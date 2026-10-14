<?php

use App\Models\ArtisanProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

it('stores an artisan payout phone without exposing it in API responses', function () {
    $user = User::create([
        'name' => 'Payout Artisan', 'email' => 'payout-artisan@example.test',
        'phone' => '237677123456', 'password' => 'A-secure-password1', 'roles' => ['artisan'],
    ]);
    $user->forceFill(['email_verified_at' => now()])->save();
    ArtisanProfile::create([
        'user_id' => $user->getKey(), 'professional_title' => 'Electrician',
        'experience_years' => 5, 'verification_status' => 'pending',
    ]);

    $response = $this->actingAs($user, 'sanctum')->patchJson('/api/artisan/profile', ['payout_phone' => '237699123456']);

    $response->assertOk()
        ->assertJsonPath('profile.payout_phone_configured', true)
        ->assertJsonMissingPath('profile.payout_phone');

    expect(ArtisanProfile::firstOrFail()->payout_phone)->toBe('237699123456');
});

it('rejects invalid artisan payout phone values', function () {
    $user = User::create([
        'name' => 'Invalid Payout Artisan', 'email' => 'invalid-payout@example.test',
        'phone' => '237677123457', 'password' => 'A-secure-password1', 'roles' => ['artisan'],
    ]);
    $user->forceFill(['email_verified_at' => now()])->save();
    ArtisanProfile::create([
        'user_id' => $user->getKey(), 'professional_title' => 'Electrician',
        'experience_years' => 5, 'verification_status' => 'pending',
    ]);

    $this->actingAs($user, 'sanctum')->patchJson('/api/artisan/profile', ['payout_phone' => '677123456'])
        ->assertUnprocessable()->assertJsonValidationErrors('payout_phone');
});
