<?php

use App\Models\User;

test('password reset does not reveal if email exists', function () {
    User::factory()->create(['email' => 'known@example.com']);

    $response1 = $this->postJson('/api/auth/forgot-password', ['email' => 'known@example.com']);
    $response2 = $this->postJson('/api/auth/forgot-password', ['email' => 'unknown@example.com']);

    $response1->assertStatus(202);
    $response2->assertStatus(202);
    expect($response1->json('message'))->toBe($response2->json('message'));
});
