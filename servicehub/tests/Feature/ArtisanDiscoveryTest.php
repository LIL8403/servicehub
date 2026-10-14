<?php

use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function artisanForDiscovery(string $email, VerificationStatus $status): array
{
    $user = User::create([
        'name' => 'Artisan '.uniqid(),
        'email' => $email,
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['artisan'],
    ]);

    return [$user, ArtisanProfile::create([
        'user_id' => $user->getKey(),
        'professional_title' => 'Electrician',
        'experience_years' => 6,
        'verification_status' => $status,
        'service_areas' => ['Yaounde'],
        'availability' => ['accepting_requests' => true],
    ])];
}

it('lets an artisan manage embedded offerings and rejects duplicate service entries', function () {
    $category = ServiceCategory::create(['name' => 'Electrical', 'slug' => 'electrical', 'is_active' => true]);
    $service = Service::create(['service_category_id' => $category->getKey(), 'name' => 'Wiring', 'slug' => 'wiring', 'is_active' => true]);
    [$artisan] = artisanForDiscovery('offering-artisan@example.test', VerificationStatus::PENDING);
    $token = $artisan->createToken('test')->plainTextToken;

    $response = $this->withToken($token)->postJson('/api/artisan/service-offerings', [
        'service_id' => $service->getKey(),
        'starting_price' => 15000,
        'description' => 'Residential wiring work',
    ]);

    $response->assertCreated()->assertJsonPath('offering.service_id', $service->getKey());

    $this->withToken($token)->postJson('/api/artisan/service-offerings', ['service_id' => $service->getKey()])
        ->assertUnprocessable();
});

it('returns only verified active matching artisans for manual discovery', function () {
    $category = ServiceCategory::create(['name' => 'Plumbing', 'slug' => 'plumbing', 'is_active' => true]);
    $service = Service::create(['service_category_id' => $category->getKey(), 'name' => 'Leak repair', 'slug' => 'leak-repair', 'is_active' => true]);
    [, $verified] = artisanForDiscovery('verified-discovery@example.test', VerificationStatus::VERIFIED);
    [, $pending] = artisanForDiscovery('pending-discovery@example.test', VerificationStatus::PENDING);

    $offering = ['offering_id' => 'verified-offering', 'service_reference' => $service->getKey(), 'is_active' => true, 'starting_price' => 10000];
    $verified->update(['service_offerings' => [$offering]]);
    $pending->update(['service_offerings' => [$offering]]);

    expect(ArtisanProfile::query()->where('verification_status', VerificationStatus::VERIFIED)->count())->toBe(1);
    expect(ArtisanProfile::findOrFail($verified->getKey())->service_offerings[0]['service_reference'])->toBe($service->getKey());

    $this->getJson('/api/artisans?service_id='.$service->getKey())
        ->assertOk()
        ->assertJsonCount(1, 'artisans')
        ->assertJsonPath('artisans.0.id', $verified->getKey())
        ->assertJsonPath('artisans.0.service_offerings.0.offering_id', 'verified-offering');
});

it('requires a service filter for manual discovery', function () {
    $this->getJson('/api/artisans')->assertUnprocessable()->assertJsonValidationErrors('service_id');
});
