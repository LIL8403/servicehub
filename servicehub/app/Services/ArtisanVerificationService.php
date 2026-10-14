<?php

namespace App\Services;

use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class ArtisanVerificationService
{
    public function getPendingArtisans()
    {
        return Artisan::with('user')
            ->where(
                'verification_status',
                VerificationStatus::PENDING
            )
            ->latest()
            ->get();
    }

    public function approve(Artisan $artisan, User $reviewer): Artisan
    {
        if (
            $artisan->verification_status !==
            VerificationStatus::PENDING
        ) {
            throw ValidationException::withMessages([
                'artisan' => [
                    'Only pending artisan applications can be verified.',
                ],
            ]);
        }

        $artisan->update([
            'verification_status' => VerificationStatus::VERIFIED,
            'rejection_reason' => null,
            'reviewed_at' => now(),
            'verification_history' => [...($artisan->verification_history ?? []), $this->history(VerificationStatus::VERIFIED, $reviewer)],
        ]);

        return $artisan->fresh(['user']);
    }

    public function reject(
        Artisan $artisan,
        string $reason,
        User $reviewer,
    ): Artisan {
        if (
            $artisan->verification_status !==
            VerificationStatus::PENDING
        ) {
            throw ValidationException::withMessages([
                'artisan' => [
                    'Only pending artisan applications can be rejected.',
                ],
            ]);
        }

        $artisan->update([
            'verification_status' => VerificationStatus::REJECTED,
            'rejection_reason' => $reason,
            'reviewed_at' => now(),
            'verification_history' => [...($artisan->verification_history ?? []), $this->history(VerificationStatus::REJECTED, $reviewer, $reason)],
        ]);

        return $artisan->fresh(['user']);
    }

    private function history(VerificationStatus $status, User $reviewer, ?string $reason = null): array
    {
        return array_filter([
            'status' => $status->value,
            'occurred_at' => now(),
            'actor_id' => $reviewer->getKey(),
            'reason' => $reason,
        ], fn (mixed $value) => $value !== null);
    }
}
