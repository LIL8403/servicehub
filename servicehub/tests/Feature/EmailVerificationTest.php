<?php

use App\Models\User;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;

test('unverified user cannot initiate payment', function () {
    $user = User::factory()->create(['email_verified_at' => null]);
    $user->assignRole('customer');

    $serviceRequest = \App\Models\ServiceRequest::factory()->create([
        'customer_id' => $user->getKey(),
        'status' => 'payment_pending',
    ]);

    $this->actingAs($user)
        ->postJson("/api/customer/service-requests/{$serviceRequest->getKey()}/payments", [])
        ->assertForbidden();
});

test('signed verification link verifies the user', function () {
    $user = User::factory()->create(['email_verified_at' => null]);

    $url = URL::temporarySignedRoute(
        'verification.verify',
        now()->addMinutes(60),
        ['id' => $user->id, 'hash' => sha1($user->email)]
    );

    $this->actingAs($user)
        ->getJson($url)
        ->assertOk()
        ->assertJsonPath('data.verified', true);

    expect($user->fresh()->hasVerifiedEmail())->toBeTrue();
});

test('invalid signed link fails safely', function () {
    $user = User::factory()->create(['email_verified_at' => null]);

    $this->actingAs($user)
        ->getJson("/api/email/verify/{$user->id}/invalid-hash")
        ->assertForbidden();
});

test('resend verification is rate limited', function () {
    $user = User::factory()->create(['email_verified_at' => null]);

    for ($i = 0; $i < 6; $i++) {
        $this->actingAs($user)->postJson('/api/email/verification-notification');
    }

    $this->actingAs($user)
        ->postJson('/api/email/verification-notification')
        ->assertStatus(429);
});
