<?php

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Cache;

uses(DatabaseMigrations::class);

beforeEach(function () {
    Cache::flush();
});

it('throttles repeated login attempts by the submitted account identity', function () {
    $payload = [
        'email' => 'rate-limit-login@example.test',
        'password' => 'A-secure-password1',
    ];

    for ($attempt = 1; $attempt <= 5; $attempt++) {
        $this->postJson('/api/auth/login', $payload)->assertUnprocessable();
    }

    $this->postJson('/api/auth/login', $payload)
        ->assertStatus(429)
        ->assertHeader('Retry-After')
        ->assertJsonPath('message', 'Too many requests. Please try again later.');
});

it('throttles AI requests per authenticated customer without affecting manual discovery', function () {
    $customer = User::create([
        'name' => 'Rate Limited Customer',
        'email' => 'rate-limit-ai@example.test',
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);

    for ($attempt = 1; $attempt <= 10; $attempt++) {
        $this->actingAs($customer, 'sanctum')
            ->postJson('/api/ai/recommend', [])
            ->assertUnprocessable();
    }

    $this->actingAs($customer, 'sanctum')
        ->postJson('/api/ai/recommend', [])
        ->assertStatus(429)
        ->assertHeader('Retry-After');

    $this->getJson('/api/artisans?service_id=manual-discovery-remains-available')
        ->assertOk();
});
