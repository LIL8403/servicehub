<?php

namespace App\Services;

use App\Enums\AccountStatus;
use App\Enums\VerificationStatus;
use App\Models\Customer;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthService
{
    public function __construct(private readonly AuditLogService $auditLogs) {}

    public function registerCustomer(array $data): array
    {
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'],
            'password' => $data['password'],
            'roles' => ['customer'],
            'active_role' => 'customer',
        ]);

        Customer::create(['user_id' => $user->getKey()]);

        return [
            'user' => $user,
            'token' => $user->createToken('servicehub')->plainTextToken,
        ];
    }

    public function login(array $credentials): array
    {
        $user = User::where('email', $credentials['email'])->first();

        if (
            ! $user ||
            ! Hash::check($credentials['password'], $user->password)
        ) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if ($user->status !== AccountStatus::ACTIVE) {
            throw ValidationException::withMessages([
                'email' => ['Your account is currently suspended.'],
            ]);
        }

        $token = $user->createToken('servicehub')->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
        ];
    }

    public function logout(User $user): void
    {
        $token = $user->currentAccessToken();

        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }
    }

    public function changePassword(User $user, string $password): void
    {
        $user->forceFill(['password' => Hash::make($password), 'remember_token' => Str::random(60)])->save();
        $tokensRevoked = $user->tokens()->delete();
        $this->auditLogs->record('account.password_changed', $user->getKey(), User::class, $user->getKey(), [
            'tokens_revoked' => $tokensRevoked,
        ]);
    }

    public function requestPasswordReset(string $email): void
    {
        try {
            Password::sendResetLink(['email' => $email]);
        } catch (\Throwable $exception) {
            Log::warning('Password reset delivery failed.', ['email_hash' => hash('sha256', mb_strtolower($email)), 'exception' => $exception::class]);
        }
    }

    public function resetPassword(array $data): void
    {
        $status = Password::reset($data, function (User $user, string $password): void {
            $user->forceFill(['password' => Hash::make($password), 'remember_token' => Str::random(60)])->save();
            $tokensRevoked = $user->tokens()->delete();
            $this->auditLogs->record('account.password_reset', $user->getKey(), User::class, $user->getKey(), [
                'tokens_revoked' => $tokensRevoked,
            ]);
            event(new PasswordReset($user));
        });

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['token' => ['The password reset request is invalid or has expired.']]);
        }
    }

    public function registerArtisan(array $data): array
    {
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'],
            'password' => $data['password'],
            // An artisan may also hire artisans. Both ledgers stay separate
            // through customer_id on payments and artisan_profile_id on payouts.
            'roles' => ['artisan', 'customer'],
            'active_role' => 'artisan',
        ]);

        try {
            Customer::create(['user_id' => $user->getKey()]);
            $artisanProfile = $user->artisan()->create([
                'professional_title' => $data['professional_title'],
                'bio' => $data['bio'] ?? null,
                'professional_description' => $data['bio'] ?? $data['professional_title'],
                'experience_years' => $data['experience_years'],
                'verification_status' => VerificationStatus::PENDING,
                'verification_history' => [[
                    'status' => VerificationStatus::PENDING->value,
                    'occurred_at' => now(),
                    'actor_id' => $user->getKey(),
                ]],
            ]);
        } catch (\Throwable $exception) {
            $user->customer()->delete();
            $user->delete();

            throw $exception;
        }

        return [
            'user' => $user,
            'artisan_profile' => $artisanProfile,
            'token' => $user->createToken('servicehub')->plainTextToken,
        ];
    }
}
