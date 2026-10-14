<?php

use App\Models\User;

test('customer cannot access artisan endpoints', function () {
    $customer = User::factory()->create();
    $customer->assignRole('customer');

    $this->actingAs($customer)
        ->getJson('/api/artisan/profile')
        ->assertForbidden();
});

test('artisan cannot access customer endpoints', function () {
    $artisan = User::factory()->create();
    $artisan->assignRole('artisan');

    $this->actingAs($artisan)
        ->getJson('/api/customer/profile')
        ->assertForbidden();
});

test('unauthenticated user is rejected', function () {
    $this->getJson('/api/customer/profile')->assertUnauthorized();
});
