<?php

use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\ServiceRequest;
use App\Models\User;

test('two artisans cannot be selected simultaneously', function () {
    $customer = User::factory()->create();
    $customer->assignRole('customer');

    $request = ServiceRequest::factory()->create([
        'customer_id' => $customer->id,
        'status' => \App\Enums\ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
        'location' => ['label' => 'Douala V', 'type' => 'Point', 'coordinates' => [9.7679, 4.0511]],
    ]);

    $firstArtisanUser = User::factory()->create(['roles' => ['artisan']]);
    $firstArtisan = Artisan::create([
        'user_id' => $firstArtisanUser->getKey(),
        'professional_title' => 'First artisan',
        'experience_years' => 3,
        'verification_status' => VerificationStatus::VERIFIED,
        'service_offerings' => [['service_reference' => $request->service_id, 'is_active' => true]],
        'service_areas' => ['Douala V'],
    ]);
    $secondArtisanUser = User::factory()->create(['roles' => ['artisan']]);
    $secondArtisan = Artisan::create([
        'user_id' => $secondArtisanUser->getKey(),
        'professional_title' => 'Second artisan',
        'experience_years' => 3,
        'verification_status' => VerificationStatus::VERIFIED,
        'service_offerings' => [['service_reference' => $request->service_id, 'is_active' => true]],
        'service_areas' => ['Douala V'],
    ]);

    $this->actingAs($customer)->postJson(
        "/api/customer/service-requests/{$request->id}/select-artisan",
        ['artisan_profile_id' => $firstArtisan->getKey()]
    );

    $this->actingAs($customer)->postJson(
        "/api/customer/service-requests/{$request->id}/select-artisan",
        ['artisan_profile_id' => $secondArtisan->getKey()]
    );

    $request->refresh();
    expect($request->selected_artisan_id)->toBe($firstArtisan->getKey());
});
