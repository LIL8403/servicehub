<?php

use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function requestCustomer(string $email): User
{
    return User::create([
        'name' => 'Request Customer',
        'email' => $email,
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);
}

function requestService(): Service
{
    $category = ServiceCategory::create(['name' => 'Request Category '.uniqid(), 'slug' => 'request-category-'.uniqid(), 'is_active' => true]);

    return Service::create(['service_category_id' => $category->getKey(), 'name' => 'Request Service '.uniqid(), 'slug' => 'request-service-'.uniqid(), 'is_active' => true]);
}

function eligibleRequestArtisan(Service $service, VerificationStatus $status = VerificationStatus::VERIFIED): ArtisanProfile
{
    $user = User::create([
        'name' => 'Request Artisan',
        'email' => 'request-artisan-'.uniqid().'@example.test',
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['artisan'],
    ]);

    return ArtisanProfile::create([
        'user_id' => $user->getKey(),
        'professional_title' => 'Plumber',
        'experience_years' => 5,
        'verification_status' => $status,
        'service_offerings' => [[
            'offering_id' => 'request-offering-'.uniqid(),
            'service_reference' => $service->getKey(),
            'is_active' => true,
        ]],
        'service_areas' => ['Yaounde', 'Bastos, Yaounde'],
    ]);
}

function requestPayload(Service $service): array
{
    return [
        'service_id' => $service->getKey(),
        'description' => 'A water pipe is leaking under the kitchen sink.',
        'location' => ['label' => 'Bastos, Yaounde', 'type' => 'Point', 'coordinates' => [11.5174, 3.8992]],
        'preferred_schedule' => ['date' => now()->addDay()->toDateString(), 'window' => 'Morning'],
    ];
}

it('creates a customer-owned request with an auditable recoverable no-artisan state when no artisan matches', function () {
    $customer = requestCustomer('request-owner@example.test');
    $service = requestService();

    $response = $this->withToken($customer->createToken('test')->plainTextToken)
        ->postJson('/api/customer/service-requests', requestPayload($service));

    $response->assertCreated()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::NO_ARTISAN_AVAILABLE->value)
        ->assertJsonPath('service_request.service_id', $service->getKey())
        ->assertJsonPath('service_request.status_history.0.status', ServiceRequestStatus::AWAITING_ARTISAN_SELECTION->value)
        ->assertJsonPath('service_request.status_history.1.status', ServiceRequestStatus::NO_ARTISAN_AVAILABLE->value);
});

it('allows the customer to explicitly select only a verified artisan offering the requested service', function () {
    $customer = requestCustomer('select-owner@example.test');
    $service = requestService();
    $artisan = eligibleRequestArtisan($service);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(), 'service_id' => $service->getKey(),
        'description' => 'Leaking pipe requires a repair assessment.',
        'location' => ['label' => 'Yaounde', 'type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
        'status_history' => [],
    ]);

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->postJson("/api/customer/service-requests/{$request->getKey()}/select-artisan", ['artisan_profile_id' => $artisan->getKey()])
        ->assertOk()
        ->assertJsonPath('service_request.status', ServiceRequestStatus::PENDING_ARTISAN_RESPONSE->value)
        ->assertJsonPath('service_request.selected_artisan_id', $artisan->getKey())
        ->assertJsonPath('service_request.status_history.0.artisan_id', $artisan->getKey());
});

it('rejects selection of an unverified artisan and hides requests from other customers', function () {
    $owner = requestCustomer('hidden-owner@example.test');
    $otherCustomer = requestCustomer('hidden-other@example.test');
    $service = requestService();
    $unverifiedArtisan = eligibleRequestArtisan($service, VerificationStatus::PENDING);
    $request = ServiceRequest::create([
        'customer_id' => $owner->getKey(), 'service_id' => $service->getKey(),
        'description' => 'Leaking pipe requires a repair assessment.',
        'location' => ['label' => 'Yaounde', 'type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
        'status_history' => [],
    ]);

    $this->withToken($otherCustomer->createToken('test')->plainTextToken)
        ->getJson("/api/customer/service-requests/{$request->getKey()}")
        ->assertNotFound();

    $this->actingAs($owner, 'sanctum')
        ->postJson("/api/customer/service-requests/{$request->getKey()}/select-artisan", ['artisan_profile_id' => $unverifiedArtisan->getKey()])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('artisan_profile_id');
});
