<?php

use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

it('finds verified artisans within the customer-selected search radius', function () {
    $category = ServiceCategory::create(['name' => 'Geo Category', 'slug' => 'geo-category', 'is_active' => true]);
    $service = Service::create(['service_category_id' => $category->getKey(), 'name' => 'Geo Service', 'slug' => 'geo-service', 'is_active' => true]);
    $nearUser = User::create(['name' => 'Near Artisan', 'email' => 'near-geo@example.test', 'phone' => '677888888', 'password' => 'A-secure-password1', 'roles' => ['artisan']]);
    $farUser = User::create(['name' => 'Far Artisan', 'email' => 'far-geo@example.test', 'phone' => '677999999', 'password' => 'A-secure-password1', 'roles' => ['artisan']]);

    $near = ArtisanProfile::create([
        'user_id' => $nearUser->getKey(), 'verification_status' => VerificationStatus::VERIFIED, 'experience_years' => 3,
        'service_location' => ['type' => 'Point', 'coordinates' => [11.501, 3.801]],
        'service_offerings' => [['offering_id' => 'near-offering', 'service_reference' => $service->getKey(), 'is_active' => true]],
    ]);
    ArtisanProfile::create([
        'user_id' => $farUser->getKey(), 'verification_status' => VerificationStatus::VERIFIED, 'experience_years' => 8,
        'service_location' => ['type' => 'Point', 'coordinates' => [11.8, 4.2]],
        'service_offerings' => [['offering_id' => 'far-offering', 'service_reference' => $service->getKey(), 'is_active' => true]],
    ]);

    $this->getJson("/api/artisans?service_id={$service->getKey()}&longitude=11.5&latitude=3.8&radius_km=5")
        ->assertOk()->assertJsonCount(1, 'artisans')->assertJsonPath('artisans.0.id', $near->getKey());
});

it('requires a complete manual location filter when geospatial search is requested', function () {
    $this->getJson('/api/artisans?service_id=service-id&longitude=11.5')
        ->assertUnprocessable()->assertJsonValidationErrors(['latitude', 'radius_km']);
});
