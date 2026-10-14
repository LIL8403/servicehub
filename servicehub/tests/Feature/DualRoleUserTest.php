<?php

use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\Customer;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function dualRoleUser(): User
{
    return User::create([
        'name' => 'Dual Role User',
        'email' => 'dual-role@example.test',
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
        'active_role' => 'customer',
    ]);
}

function dualRoleService(): Service
{
    $suffix = uniqid();
    $category = ServiceCategory::create(['name' => "Dual Role {$suffix}", 'slug' => "dual-role-{$suffix}", 'is_active' => true]);

    return Service::create(['service_category_id' => $category->getKey(), 'name' => "Electrical {$suffix}", 'slug' => "electrical-{$suffix}", 'is_active' => true]);
}

it('converts a customer to an artisan without removing the customer account', function () {
    $user = dualRoleUser();

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/user/become-artisan', [
            'professional_description' => 'Licensed electrician for residential electrical maintenance and repairs.',
            'experience_years' => 6,
            'languages' => ['English', 'French'],
        ])
        ->assertCreated()
        ->assertJsonPath('active_role', 'artisan')
        ->assertJsonPath('artisan.verification_status', VerificationStatus::PENDING->value);

    $user->refresh();
    expect($user->roles)->toContain('customer', 'artisan')
        ->and(Customer::query()->where('user_id', $user->getKey())->exists())->toBeTrue()
        ->and(Artisan::query()->where('user_id', $user->getKey())->exists())->toBeTrue();
});

it('switches a dual-role user between customer and artisan dashboards', function () {
    $user = dualRoleUser();
    Artisan::create([
        'user_id' => $user->getKey(),
        'professional_description' => 'Experienced plumber who handles domestic pipe repairs and installations.',
        'experience_years' => 4,
        'verification_status' => VerificationStatus::PENDING,
    ]);
    $user->syncRoles(['customer', 'artisan']);

    $this->actingAs($user, 'sanctum')->postJson('/api/user/switch-role', ['role' => 'artisan'])
        ->assertOk()->assertJsonPath('active_role', 'artisan');
    $this->actingAs($user->fresh(), 'sanctum')->postJson('/api/user/switch-role', ['role' => 'customer'])
        ->assertOk()->assertJsonPath('active_role', 'customer');
    $this->actingAs($user->fresh(), 'sanctum')->getJson('/api/user/roles')
        ->assertOk()->assertJsonPath('roles.0', 'customer');
});

it('refuses an artisan dashboard switch when the artisan profile is incomplete', function () {
    $user = dualRoleUser();
    Artisan::create(['user_id' => $user->getKey(), 'verification_status' => VerificationStatus::PENDING]);
    $user->syncRoles(['customer', 'artisan']);

    $this->actingAs($user, 'sanctum')->postJson('/api/user/switch-role', ['role' => 'artisan'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('role');
});

it('enforces roles while allowing one dual-role user to submit and receive a service request', function () {
    $user = dualRoleUser();
    $service = dualRoleService();
    $artisan = Artisan::create([
        'user_id' => $user->getKey(),
        'professional_description' => 'Verified electrician delivering household electrical repairs and installation work.',
        'experience_years' => 8,
        'verification_status' => VerificationStatus::VERIFIED,
        'service_offerings' => [[
            'offering_id' => 'dual-role-offering', 'service_reference' => $service->getKey(), 'is_active' => true,
        ]],
        'service_areas' => ['Bastos, Yaounde'],
    ]);
    $user->syncRoles(['customer', 'artisan']);

    $this->actingAs($user, 'sanctum')->postJson('/api/customer/service-requests', [
        'service_id' => $service->getKey(),
        'description' => 'The circuit breaker trips whenever the kitchen sockets are used.',
        'location' => ['label' => 'Bastos, Yaounde', 'type' => 'Point', 'coordinates' => [11.5174, 3.8992]],
    ])->assertCreated();

    $requestId = $this->actingAs($user, 'sanctum')->getJson('/api/customer/service-requests')->json('service_requests.0.id');
    $this->actingAs($user, 'sanctum')->postJson("/api/customer/service-requests/{$requestId}/select-artisan", ['artisan_profile_id' => $artisan->getKey()])
        ->assertOk();
    $this->actingAs($user, 'sanctum')->postJson("/api/artisan/service-requests/{$requestId}/approve")
        ->assertOk();
    $this->actingAs($user, 'sanctum')->postJson("/api/artisan/service-requests/{$requestId}/quotation", [
        'labor_amount' => 15000, 'currency' => 'XAF', 'scope' => 'Diagnose the kitchen circuit and replace the faulty breaker.', 'valid_until' => now()->addDays(3)->toIso8601String(),
    ])->assertOk();

    $customerOnly = User::create(['name' => 'Customer Only', 'email' => 'customer-only-dual@example.test', 'phone' => '677'.random_int(100000, 999999), 'password' => 'A-secure-password1', 'roles' => ['customer']]);
    $this->actingAs($customerOnly, 'sanctum')->getJson('/api/artisan/profile')->assertForbidden();
});
