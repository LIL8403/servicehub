<?php

use App\Enums\AccountStatus;
use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\AuditLog;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function managedAccount(string $role, string $email): User
{
    return User::create([
        'name' => ucfirst($role).' Account',
        'email' => $email,
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => [$role],
    ]);
}

function managedArtisan(User $user, Service $service): ArtisanProfile
{
    return ArtisanProfile::create([
        'user_id' => $user->getKey(),
        'professional_title' => 'Electrician',
        'experience_years' => 5,
        'verification_status' => VerificationStatus::VERIFIED,
        'service_offerings' => [[
            'offering_id' => 'managed-offering-'.uniqid(),
            'service_reference' => $service->getKey(),
            'is_active' => true,
        ]],
    ]);
}

function managedService(): Service
{
    $suffix = uniqid();
    $category = ServiceCategory::create([
        'name' => 'Managed Accounts '.$suffix,
        'slug' => 'managed-accounts-'.$suffix,
        'is_active' => true,
    ]);

    return Service::create([
        'service_category_id' => $category->getKey(),
        'name' => 'Managed Electrical Work '.$suffix,
        'slug' => 'managed-electrical-work-'.$suffix,
        'is_active' => true,
    ]);
}

it('suspends an artisan account, revokes tokens, and removes verified status', function () {
    $admin = managedAccount('admin', 'account-admin@example.test');
    $artisanUser = managedAccount('artisan', 'managed-artisan@example.test');
    $service = managedService();
    $artisan = managedArtisan($artisanUser, $service);
    $artisanToken = $artisanUser->createToken('artisan-device')->plainTextToken;
    expect($artisanUser->tokens()->count())->toBe(1);

    $this->actingAs($admin, 'sanctum')
        ->patchJson("/api/admin/users/{$artisanUser->getKey()}/status", [
            'status' => AccountStatus::SUSPENDED->value,
            'reason' => 'Verified identity information requires a security review.',
        ])
        ->assertOk()
        ->assertJsonPath('user.id', $artisanUser->getKey())
        ->assertJsonPath('user.status', AccountStatus::SUSPENDED->value);

    expect($artisanUser->fresh()->status)->toBe(AccountStatus::SUSPENDED)
        ->and($artisan->fresh()->verification_status)->toBe(VerificationStatus::SUSPENDED)
        ->and($artisanUser->fresh()->tokens()->count())->toBe(0)
        ->and(AuditLog::query()->where('event_type', 'account.status_changed')->count())->toBe(1);

    $this->app['auth']->forgetGuards();
    $this->withToken($artisanToken)->getJson('/api/artisan/profile')->assertUnauthorized();
    $this->getJson('/api/artisans?service_id='.$service->getKey())
        ->assertOk()
        ->assertJsonMissing(['id' => $artisan->getKey()]);
});

it('lists account-management data without exposing credentials and enforces administrator authorization', function () {
    $admin = managedAccount('admin', 'listing-admin@example.test');
    $artisan = managedAccount('artisan', 'listing-artisan@example.test');
    $customer = managedAccount('customer', 'listing-customer@example.test');
    expect(User::query()->whereIn('roles', ['artisan'])->count())->toBe(1)
        ->and(User::query()->where('status', AccountStatus::ACTIVE->value)->count())->toBe(3);

    $this->actingAs($admin, 'sanctum')->getJson('/api/admin/users?role=artisan&status=active&per_page=1')
        ->assertOk()
        ->assertJsonPath('users.0.id', $artisan->getKey())
        ->assertJsonPath('users.0.status', AccountStatus::ACTIVE->value)
        ->assertJsonMissingPath('users.0.password');

    $this->actingAs($customer, 'sanctum')->getJson('/api/admin/users')->assertForbidden();
    $this->actingAs($customer, 'sanctum')->patchJson("/api/admin/users/{$artisan->getKey()}/status", [
        'status' => AccountStatus::SUSPENDED->value,
        'reason' => 'An unauthorized user must not change account status.',
    ])->assertForbidden();
});

it('does not let an administrator suspend their own account', function () {
    $admin = managedAccount('admin', 'self-status-admin@example.test');

    $this->actingAs($admin, 'sanctum')
        ->patchJson("/api/admin/users/{$admin->getKey()}/status", [
            'status' => AccountStatus::SUSPENDED->value,
            'reason' => 'This account must remain protected from self-lockout.',
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('user');

    expect($admin->fresh()->status)->toBe(AccountStatus::ACTIVE);
});
