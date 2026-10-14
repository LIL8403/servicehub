<?php

use App\Enums\ServiceRequestStatus;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function selectedRequestFixture(): array
{
    $customer = requestCustomer('inspection-customer-'.uniqid().'@example.test');
    $service = requestService();
    $artisanProfile = eligibleRequestArtisan($service);
    $artisan = User::findOrFail($artisanProfile->user_id);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(),
        'service_id' => $service->getKey(),
        'selected_artisan_id' => $artisanProfile->getKey(),
        'description' => 'A water pipe is leaking under the kitchen sink.',
        'location' => ['label' => 'Yaounde', 'type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::ARTISAN_APPROVED,
        'status_history' => [],
    ]);

    return [$customer, $artisan, $request];
}

it('enforces the optional inspection flow and records its lifecycle', function () {
    [$customer, $artisan, $request] = selectedRequestFixture();

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->postJson("/api/customer/service-requests/{$request->getKey()}/inspection", [
            'scheduled_at' => now()->addDays(2)->toIso8601String(),
            'call_out_fee' => 5000,
            'notes' => 'Please call before arriving.',
        ])
        ->assertOk()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::INSPECTION_SCHEDULED->value)
        ->assertJsonPath('service_request.inspection.call_out_fee', 5000);

    $this->actingAs($artisan, 'sanctum')
        ->postJson("/api/artisan/service-requests/{$request->getKey()}/inspection/complete", [
            'findings' => 'The damaged pipe section must be replaced before testing the connection.',
        ])
        ->assertOk()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::INSPECTION_COMPLETED->value)
        ->assertJsonPath('service_request.inspection.status', 'completed');
});

it('allows only the selected artisan to submit and the customer to decide a quotation', function () {
    [$customer, $artisan, $request] = selectedRequestFixture();
    $otherArtisan = User::create([
        'name' => 'Other Artisan', 'email' => 'other-quote-'.uniqid().'@example.test',
        'phone' => '677'.random_int(100000, 999999), 'password' => 'A-secure-password1', 'roles' => ['artisan'],
    ]);

    $this->actingAs($otherArtisan, 'sanctum')
        ->postJson("/api/artisan/service-requests/{$request->getKey()}/quotation", [
            'labor_amount' => 15000, 'currency' => 'XAF', 'scope' => 'Replace damaged pipe and test the kitchen connection.', 'valid_until' => now()->addDays(3)->toIso8601String(),
        ])
        ->assertNotFound();

    $this->actingAs($artisan, 'sanctum')
        ->postJson("/api/artisan/service-requests/{$request->getKey()}/quotation", [
            'labor_amount' => 15000, 'currency' => 'XAF', 'scope' => 'Replace damaged pipe and test the kitchen connection.', 'valid_until' => now()->addDays(3)->toIso8601String(),
        ])
        ->assertOk()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::QUOTATION_RECEIVED->value)
        ->assertJsonPath('service_request.quotation.labor_amount', 15000);

    $this->actingAs($customer, 'sanctum')
        ->postJson("/api/customer/service-requests/{$request->getKey()}/quotation/accept")
        ->assertOk()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::PAYMENT_PENDING->value)
        ->assertJsonPath('service_request.quotation.status', 'accepted');
});

it('returns a quotation to pending when the customer rejects it with a reason', function () {
    [$customer, $artisan, $request] = selectedRequestFixture();

    $this->actingAs($artisan, 'sanctum')->postJson("/api/artisan/service-requests/{$request->getKey()}/quotation", [
        'labor_amount' => 22000, 'currency' => 'XAF', 'scope' => 'Replace damaged pipe and test the kitchen connection.', 'valid_until' => now()->addDays(3)->toIso8601String(),
    ])->assertOk();

    $this->actingAs($customer, 'sanctum')
        ->postJson("/api/customer/service-requests/{$request->getKey()}/quotation/reject", ['reason' => 'Please provide a clearer breakdown of the labor estimate.'])
        ->assertOk()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::QUOTATION_PENDING->value)
        ->assertJsonPath('service_request.quotation.status', 'rejected');
});
