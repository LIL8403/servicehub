<?php

namespace App\Services;

use App\Models\PlatformNotification;
use App\Models\User;

class PlatformNotificationService
{
    /** @param array<string, mixed> $payload */
    public function notifyUser(string $recipientId, string $type, string $title, string $body, array $payload = []): PlatformNotification
    {
        return PlatformNotification::create([
            'recipient_id' => $recipientId,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'payload' => $payload,
        ]);
    }

    /** @param array<string, mixed> $payload */
    public function notifyAdmins(string $type, string $title, string $body, array $payload = []): void
    {
        User::query()->get()
            ->filter(fn (User $user) => $user->hasRole('admin'))
            ->each(fn (User $user) => $this->notifyUser($user->getKey(), $type, $title, $body, $payload));
    }
}
