<?php

use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

it('registers a customer and issues a usable personal access token', function () {
    $response = $this->postJson('/api/auth/register/customer', [
        'name' => 'Marie Ndam',
        'email' => 'marie@example.test',
        'phone' => '677123456',
        'password' => 'A-secure-password1',
        'password_confirmation' => 'A-secure-password1',
    ]);

    $response->assertCreated()
        ->assertJsonPath('user.email', 'marie@example.test')
        ->assertJsonPath('user.roles.0', 'customer')
        ->assertJsonStructure(['token']);

    expect(User::where('email', 'marie@example.test')->firstOrFail()->hasRole('customer'))->toBeTrue();

    $this->withToken($response->json('token'))
        ->getJson('/api/auth/me')
        ->assertOk()
        ->assertJsonPath('user.email', 'marie@example.test');
});

it('validates uniqueness and does not issue a second customer account', function () {
    User::create([
        'name' => 'Existing Customer',
        'email' => 'existing@example.test',
        'phone' => '677000001',
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);

    $this->postJson('/api/auth/register/customer', [
        'name' => 'Another Customer',
        'email' => 'existing@example.test',
        'phone' => '677000002',
        'password' => 'A-secure-password1',
        'password_confirmation' => 'A-secure-password1',
    ])->assertUnprocessable()->assertJsonValidationErrors('email');
});

it('creates a pending artisan profile and protects administrator verification routes', function () {
    $response = $this->postJson('/api/auth/register/artisan', [
        'name' => 'Jean Artisan',
        'email' => 'jean@example.test',
        'phone' => '677123457',
        'password' => 'A-secure-password1',
        'password_confirmation' => 'A-secure-password1',
        'professional_title' => 'Electrician',
        'experience_years' => 7,
    ]);

    $response->assertCreated()
        ->assertJsonPath('user.roles.0', 'artisan')
        ->assertJsonPath('artisan_profile.verification_status', 'pending');

    expect(ArtisanProfile::firstOrFail()->verification_status)->toBe(VerificationStatus::PENDING);

    $this->withToken($response->json('token'))
        ->getJson('/api/admin/artisans/pending')
        ->assertForbidden();
});
