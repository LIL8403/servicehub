<?php

use App\Models\PlatformNotification;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

function notificationUser(string $email): User
{
    return User::create([
        'name' => 'Notification User', 'email' => $email, 'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1', 'roles' => ['customer'], 'active_role' => 'customer',
    ]);
}

it('lists and marks only the authenticated users notifications as read', function () {
    $owner = notificationUser('notification-owner@example.test');
    $outsider = notificationUser('notification-outsider@example.test');
    $notification = PlatformNotification::create([
        'recipient_id' => $owner->getKey(), 'type' => 'test', 'title' => 'Test notification', 'body' => 'Secure notification body.',
        'payload' => ['service_request_id' => 'request-1', 'token' => 'must-not-leak'],
    ]);

    $this->actingAs($owner, 'sanctum')->getJson('/api/user/notifications')
        ->assertOk()
        ->assertJsonPath('notifications.0.id', $notification->getKey())
        ->assertJsonPath('meta.unread_count', 1)
        ->assertJsonMissingPath('notifications.0.payload.token');

    $this->actingAs($outsider, 'sanctum')->patchJson("/api/user/notifications/{$notification->getKey()}/read")
        ->assertNotFound();
    $this->actingAs($owner, 'sanctum')->patchJson("/api/user/notifications/{$notification->getKey()}/read")
        ->assertOk()
        ->assertJsonPath('notification.id', $notification->getKey());

    expect($notification->fresh()->read_at)->not->toBeNull();
});
