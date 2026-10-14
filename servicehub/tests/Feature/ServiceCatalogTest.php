<?php

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function catalogAdminToken(): string
{
    return User::create([
        'name' => 'Catalog Administrator',
        'email' => 'catalog-admin@example.test',
        'phone' => '677222222',
        'password' => 'A-secure-password1',
        'roles' => ['admin'],
    ])->createToken('test')->plainTextToken;
}

it('shows only active catalog entries to unauthenticated users', function () {
    $activeCategory = ServiceCategory::create(['name' => 'Plumbing', 'slug' => 'plumbing', 'is_active' => true]);
    ServiceCategory::create(['name' => 'Legacy', 'slug' => 'legacy', 'is_active' => false]);
    Service::create(['service_category_id' => $activeCategory->getKey(), 'name' => 'Pipe repair', 'slug' => 'pipe-repair', 'is_active' => true]);
    Service::create(['service_category_id' => $activeCategory->getKey(), 'name' => 'Hidden repair', 'slug' => 'hidden-repair', 'is_active' => false]);

    $this->getJson('/api/service-categories')
        ->assertOk()
        ->assertJsonCount(1, 'categories')
        ->assertJsonPath('categories.0.slug', 'plumbing');

    $this->getJson('/api/services?category=plumbing')
        ->assertOk()
        ->assertJsonCount(1, 'services')
        ->assertJsonPath('services.0.slug', 'pipe-repair');
});

it('prevents non-administrators from managing the catalog', function () {
    $customer = User::create([
        'name' => 'Customer',
        'email' => 'catalog-customer@example.test',
        'phone' => '677222223',
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->postJson('/api/admin/service-categories', ['name' => 'Electrical'])
        ->assertForbidden();
});

it('allows administrators to create services and prevents deleting their category', function () {
    $token = catalogAdminToken();

    $categoryResponse = $this->withToken($token)
        ->postJson('/api/admin/service-categories', ['name' => 'Electrical Installation']);

    $categoryResponse->assertCreated()
        ->assertJsonPath('category.slug', 'electrical-installation');

    $categoryId = $categoryResponse->json('category.id');

    $this->withToken($token)
        ->postJson('/api/admin/services', [
            'service_category_id' => $categoryId,
            'name' => 'Domestic wiring',
            'description' => 'Safe residential electrical installation.',
        ])
        ->assertCreated()
        ->assertJsonPath('service.slug', 'domestic-wiring');

    $this->withToken($token)
        ->deleteJson("/api/admin/service-categories/{$categoryId}")
        ->assertConflict();
});

it('validates category input and rejects unknown service categories', function () {
    $token = catalogAdminToken();

    $this->withToken($token)
        ->postJson('/api/admin/service-categories', ['name' => 'E'])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('name');

    $this->withToken($token)
        ->postJson('/api/admin/services', [
            'service_category_id' => '66d9f1c6b80c7d1fbf9f1234',
            'name' => 'Unknown category service',
        ])
        ->assertNotFound();
});
