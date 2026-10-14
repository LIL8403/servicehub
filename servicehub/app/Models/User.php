<?php

namespace App\Models;

use App\Enums\AccountStatus;
use Database\Factories\UserFactory;
use Illuminate\Auth\Passwords\CanResetPassword as CanResetPasswordTrait;
use Illuminate\Contracts\Auth\CanResetPassword;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Contracts\Auth\MustVerifyEmail;

class User extends Authenticatable implements CanResetPassword, MustVerifyEmail
{
    /** @use HasFactory<UserFactory> */
    use CanResetPasswordTrait, HasApiTokens, HasFactory, Notifiable;

    protected $attributes = [
        'account_status' => AccountStatus::ACTIVE->value,
        // Retained during the API/data migration for legacy indexed queries.
        'status' => AccountStatus::ACTIVE->value,
        'roles' => [],
    ];

    /**
     * The attributes that are mass assignable
     */
    protected $fillable = [
        'name',
        'first_name',
        'last_name',
        'email',
        'phone',
        'password',
        'account_status',
        'status',
        'roles',
        'active_role',
    ];

    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
        'profile_photo',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'account_status' => AccountStatus::class,
        ];
    }

    public function assignRole(string $role): void
    {
        $roles = $this->roles ?? [];

        if (! in_array($role, $roles, true)) {
            $this->forceFill([
                'roles' => [...$roles, $role],
                'active_role' => $this->active_role ?? $role,
            ])->save();
        }
    }

    public function syncRoles(array $roles): void
    {
        $roles = array_values(array_unique($roles));
        $this->forceFill([
            'roles' => $roles,
            'active_role' => in_array($this->active_role, $roles, true) ? $this->active_role : ($roles[0] ?? null),
        ])->save();
    }

    public function hasRole(string $role): bool
    {
        return in_array($role, $this->roles ?? [], true);
    }

    public function sendEmailVerificationNotification(): void
    {
        $this->notify(new \App\Notifications\VerifyEmailNotification());
    }

    public function hasVerifiedEmail(): bool
    {
        return ! is_null($this->email_verified_at);
    }

    public function hasPermission(string $permission): bool
    {
        foreach ($this->roles ?? [] as $role) {
            $permissions = config("roles.permissions.{$role}", []);
            if (in_array('*', $permissions, true) || in_array($permission, $permissions, true)) {
                return true;
            }
        }

        return false;
    }

    public function customer(): HasOne
    {
        return $this->hasOne(Customer::class);
    }

    public function artisan(): HasOne
    {
        return $this->hasOne(Artisan::class);
    }

    public function administrator(): HasOne
    {
        return $this->hasOne(Administrator::class);
    }

    /** @deprecated Use artisan(). */
    public function artisanProfile(): HasOne
    {
        return $this->hasOne(ArtisanProfile::class);
    }

    public function getStatusAttribute(): ?AccountStatus
    {
        return $this->account_status;
    }

    public function setStatusAttribute(AccountStatus|string $status): void
    {
        $value = $status instanceof AccountStatus ? $status->value : $status;
        $this->attributes['account_status'] = $value;
        $this->attributes['status'] = $value;
    }

    public function setAccountStatusAttribute(AccountStatus|string $status): void
    {
        $value = $status instanceof AccountStatus ? $status->value : $status;
        $this->attributes['account_status'] = $value;
        $this->attributes['status'] = $value;
    }

    public function setNameAttribute(string $name): void
    {
        $name = trim($name);
        $parts = preg_split('/\s+/', $name, 2, PREG_SPLIT_NO_EMPTY) ?: [];

        $this->attributes['name'] = $name;
        $this->attributes['first_name'] = $this->attributes['first_name'] ?? ($parts[0] ?? null);
        $this->attributes['last_name'] = $this->attributes['last_name'] ?? ($parts[1] ?? null);
    }
}
