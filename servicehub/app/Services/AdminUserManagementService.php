<?php

namespace App\Services;

use App\Enums\AccountStatus;
use App\Enums\VerificationStatus;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class AdminUserManagementService
{
    public function __construct(private readonly AuditLogService $auditLogs) {}

    public function paginate(array $filters)
    {
        $users = User::query()->latest();

        if (isset($filters['search']) && $filters['search'] !== '') {
            $search = $filters['search'];
            $users->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        if (isset($filters['role'])) {
            $users->whereIn('roles', [$filters['role']]);
        }

        if (isset($filters['status'])) {
            $users->where('account_status', $filters['status']);
        }

        return $users->paginate($filters['per_page'] ?? 25);
    }

    public function updateStatus(User $account, AccountStatus $status, string $reason, User $actor): User
    {
        if ($account->getKey() === $actor->getKey()) {
            throw ValidationException::withMessages([
                'user' => ['Administrators cannot change their own account status.'],
            ]);
        }

        if ($account->status === $status) {
            return $account;
        }

        if ($this->wouldSuspendTheLastActiveAdministrator($account, $status)) {
            throw ValidationException::withMessages([
                'status' => ['At least one active administrator account must remain available.'],
            ]);
        }

        $previousStatus = $account->status;
        $tokensRevoked = 0;

        if ($status === AccountStatus::SUSPENDED) {
            $tokensRevoked = $account->tokens()->delete();
            $this->suspendArtisanProfile($account, $actor, $reason);
        }

        $account->update(['account_status' => $status]);

        $this->auditLogs->record('account.status_changed', $actor->getKey(), User::class, $account->getKey(), [
            'previous_status' => $previousStatus->value,
            'status' => $status->value,
            'reason' => $reason,
            'tokens_revoked' => $tokensRevoked,
        ]);

        return $account->fresh();
    }

    private function wouldSuspendTheLastActiveAdministrator(User $account, AccountStatus $status): bool
    {
        if ($status !== AccountStatus::SUSPENDED || ! $account->hasRole('admin')) {
            return false;
        }

        return User::query()
            ->where('account_status', AccountStatus::ACTIVE->value)
            ->get()
            ->filter(fn(User $user) => $user->hasRole('admin'))
            ->count() <= 1;
    }

    private function suspendArtisanProfile(User $account, User $actor, string $reason): void
    {
        $profile = $account->artisan()->first();

        if ($profile === null || $profile->verification_status === VerificationStatus::SUSPENDED) {
            return;
        }

        $account->artisan()->update([
            'verification_status' => VerificationStatus::SUSPENDED,
            'verification_history' => [...($profile->verification_history ?? []), [
                'status' => VerificationStatus::SUSPENDED->value,
                'occurred_at' => now(),
                'actor_id' => $actor->getKey(),
                'reason' => $reason,
            ]],
        ]);
    }
}
