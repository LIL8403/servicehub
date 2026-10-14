<?php

use App\Enums\DisputeStatus;
use App\Enums\PaymentStatus;
use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\Dispute;
use App\Models\Payment;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function disputeScenario(): array
{
    $customer = User::create(['name' => 'Dispute Customer', 'email' => 'dispute-customer@example.test', 'phone' => '677111111', 'password' => 'A-secure-password1', 'roles' => ['customer']]);
    $artisanUser = User::create(['name' => 'Dispute Artisan', 'email' => 'dispute-artisan@example.test', 'phone' => '677222222', 'password' => 'A-secure-password1', 'roles' => ['artisan']]);
    $category = ServiceCategory::create(['name' => 'Dispute Category', 'slug' => 'dispute-category', 'is_active' => true]);
    $service = Service::create(['service_category_id' => $category->getKey(), 'name' => 'Dispute Service', 'slug' => 'dispute-service', 'is_active' => true]);
    $artisan = ArtisanProfile::create(['user_id' => $artisanUser->getKey(), 'professional_title' => 'Plumber', 'verification_status' => VerificationStatus::VERIFIED]);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(), 'service_id' => $service->getKey(), 'selected_artisan_id' => $artisan->getKey(),
        'description' => 'A repair needs review.', 'location' => ['type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::AWAITING_CONFIRMATION, 'status_history' => [],
    ]);
    $payment = Payment::create([
        'service_request_id' => $request->getKey(), 'customer_id' => $customer->getKey(), 'amount' => 15000,
        'currency' => 'XAF', 'status' => PaymentStatus::HELD, 'provider' => 'campay', 'idempotency_key' => 'a20c7c25-1b2f-4f09-9d07-b313dda7b193',
        'external_reference' => 'SH-dispute', 'events' => [],
    ]);
    $request->update(['payment_id' => $payment->getKey()]);

    return [$customer, $artisanUser, $request, $payment];
}

it('opens a participant dispute while retaining the held payment for controlled resolution', function () {
    [$customer, $artisanUser, $request, $payment] = disputeScenario();

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/disputes", [
        'reason' => 'Work quality concern', 'description' => 'The reported repair result needs an administrator review.', 'evidence' => ['photo-reference-1'],
    ])->assertCreated()->assertJsonPath('dispute.status', DisputeStatus::OPENED->value);

    expect($request->fresh()->status)->toBe(ServiceRequestStatus::DISPUTED);
    expect($payment->fresh()->status)->toBe(PaymentStatus::HELD);

    $this->actingAs($artisanUser, 'sanctum')->getJson('/api/artisan/disputes')
        ->assertOk()->assertJsonCount(1, 'disputes');

    $admin = User::create(['name' => 'Dispute Admin', 'email' => 'dispute-admin@example.test', 'phone' => '677333333', 'password' => 'A-secure-password1', 'roles' => ['admin']]);
    $dispute = Dispute::firstOrFail();
    $this->actingAs($admin, 'sanctum')->postJson("/api/admin/disputes/{$dispute->getKey()}/review", ['notes' => 'Evidence review has started.'])
        ->assertOk()->assertJsonPath('dispute.status', DisputeStatus::UNDER_REVIEW->value);

    expect($payment->fresh()->status)->toBe(PaymentStatus::HELD);
});

it('hides a dispute from users who are not request participants', function () {
    [$customer, , $request] = disputeScenario();
    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/disputes", [
        'reason' => 'Work quality concern', 'description' => 'The reported repair result needs an administrator review.',
    ])->assertCreated();

    $outsider = User::create(['name' => 'Outsider', 'email' => 'dispute-outsider@example.test', 'phone' => '677444444', 'password' => 'A-secure-password1', 'roles' => ['customer']]);
    $dispute = Dispute::firstOrFail();
    $this->actingAs($outsider, 'sanctum')->postJson("/api/customer/disputes/{$dispute->getKey()}/evidence", ['message' => 'I should not access this.'])
        ->assertNotFound();
});
