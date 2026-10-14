<?php

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

it('allows a customer to maintain a manually entered GeoJSON default location', function () {
    $customer = User::create([
        'name' => 'Customer Profile',
        'email' => 'profile-customer@example.test',
        'phone' => '677333333',
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->patchJson('/api/customer/profile', [
            'default_location' => [
                'label' => 'Bastos, Yaounde',
                'type' => 'Point',
                'coordinates' => [11.5174, 3.8992],
            ],
            'preferences' => ['contact_method' => 'phone'],
        ])
        ->assertOk()
        ->assertJsonPath('profile.customer_profile.default_location.type', 'Point')
        ->assertJsonPath('profile.customer_profile.default_location.coordinates.0', 11.5174);
});

it('prevents a customer from accessing artisan profile operations', function () {
    $customer = User::create([
        'name' => 'Customer Profile',
        'email' => 'blocked-customer@example.test',
        'phone' => '677333334',
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->getJson('/api/artisan/profile')
        ->assertForbidden();
});

it('keeps verification state server controlled and audits an administrator verification decision', function () {
    $artisanResponse = $this->postJson('/api/auth/register/artisan', [
        'name' => 'Verified Artisan',
        'email' => 'verified-artisan@example.test',
        'phone' => '677333335',
        'password' => 'A-secure-password1',
        'password_confirmation' => 'A-secure-password1',
        'professional_title' => 'Plumber',
        'experience_years' => 4,
    ])->assertCreated();

    $artisanUser = User::findOrFail($artisanResponse->json('user.id'));
    $artisanUser->forceFill(['email_verified_at' => now()])->save();

    $artisanToken = $artisanResponse->json('token');

    $this->withToken($artisanToken)
        ->patchJson('/api/artisan/profile', [
            'professional_title' => 'Senior Plumber',
            'verification_status' => 'verified',
        ])
        ->assertOk()
        ->assertJsonPath('profile.verification_status', 'pending');

    $admin = User::create([
        'name' => 'Verification Admin',
        'email' => 'verification-admin@example.test',
        'phone' => '677333336',
        'password' => 'A-secure-password1',
        'roles' => ['admin'],
    ]);

    $profileId = $artisanResponse->json('artisan_profile.id');

    expect($admin->hasPermission('*'))->toBeTrue();

    $this->actingAs($admin, 'sanctum')
        ->postJson("/api/admin/artisans/{$profileId}/approve")
        ->assertOk()
        ->assertJsonPath('artisan_profile.verification_status', 'verified')
        ->assertJsonCount(2, 'artisan_profile.verification_history')
        ->assertJsonPath('artisan_profile.verification_history.1.actor_id', $admin->getKey());
});
