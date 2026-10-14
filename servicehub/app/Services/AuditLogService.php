<?php

namespace App\Services;

use App\Models\AuditLog;

class AuditLogService
{
    /** @param array<string, mixed> $metadata */
    public function record(string $eventType, ?string $actorId, string $subjectType, string $subjectId, array $metadata = []): AuditLog
    {
        return AuditLog::create([
            'event_type' => $eventType,
            'actor_id' => $actorId,
            'subject_type' => $subjectType,
            'subject_id' => $subjectId,
            'metadata' => $this->sanitize($metadata),
            'expires_at' => now()->addYears(5),
        ]);
    }

    /**
     * Audit data must be useful for investigation without becoming a second
     * store of payment credentials, phone numbers, or provider secrets.
     */
    public function sanitize(mixed $value): mixed
    {
        if (! is_array($value)) {
            return $value;
        }

        $sanitized = [];

        foreach ($value as $key => $item) {
            if (is_string($key) && $this->isSensitiveKey($key)) {
                continue;
            }

            $sanitized[$key] = $this->sanitize($item);
        }

        return $sanitized;
    }

    private function isSensitiveKey(string $key): bool
    {
        return in_array(strtolower($key), [
            'phone', 'phone_number', 'msisdn', 'from', 'to', 'token', 'authorization',
            'password', 'secret', 'api_key', 'signature', 'body',
        ], true);
    }
}
