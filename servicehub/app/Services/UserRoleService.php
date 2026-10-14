<?php

namespace App\Services;

use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\Customer;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class UserRoleService
{
    public function becomeArtisan(User $user, array $data): Artisan
    {
        $this->ensureNotAdministrator($user);

        if ($user->hasRole('artisan') || $user->artisan()->exists()) {
            throw ValidationException::withMessages(['role' => ['This account already has an artisan profile.']]);
        }

        Customer::query()->firstOrCreate(['user_id' => $user->getKey()]);
        $artisan = $user->artisan()->create([
            ...$data,
            'professional_title' => str($data['professional_description'])->limit(100, '')->toString(),
            'bio' => $data['professional_description'],
            'verification_status' => VerificationStatus::UNVERIFIED,
            'verification_history' => [[
                'status' => VerificationStatus::UNVERIFIED->value,
                'occurred_at' => now(),
                'actor_id' => $user->getKey(),
            ]],
        ]);

        $roles = array_values(array_unique([...($user->roles ?? []), 'customer', 'artisan']));
        $user->update(['roles' => $roles, 'active_role' => 'artisan']);

        return $artisan->fresh();
    }

    public function switchRole(User $user, string $role): User
    {
        $this->ensureNotAdministrator($user);

        if (! $user->hasRole($role)) {
            throw ValidationException::withMessages(['role' => ['This role is not assigned to your account.']]);
        }

        if ($role === 'artisan' && ! $user->artisan()->first()?->isProfileComplete()) {
            throw ValidationException::withMessages(['role' => ['Complete your artisan profile before switching to the artisan dashboard.']]);
        }

        $user->update(['active_role' => $role]);

        return $user->fresh();
    }

    private function ensureNotAdministrator(User $user): void
    {
        if ($user->hasRole('admin')) {
            throw ValidationException::withMessages(['role' => ['Administrator accounts cannot become customers or artisans.']]);
        }
    }
}
