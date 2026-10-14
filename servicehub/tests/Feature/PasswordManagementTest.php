<?php

use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;

uses(DatabaseMigrations::class);

function passwordUser(): User
{
    return User::create([
        'name' => 'Password User',
        'email' => 'password-user@example.test',
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'Current-password1',
        'roles' => ['customer'],
        'active_role' => 'customer',
    ]);
}

it('changes a password only when the current password is valid and revokes tokens', function () {
    $user = passwordUser();
    $token = $user->createToken('existing-session')->plainTextToken;

    $this->withToken($token)->putJson('/api/auth/password', [
        'current_password' => 'wrong-password',
        'password' => 'New-secure-password1',
        'password_confirmation' => 'New-secure-password1',
    ])->assertUnprocessable()->assertJsonValidationErrors('current_password');

    $this->actingAs($user, 'sanctum')->putJson('/api/auth/password', [
        'current_password' => 'Current-password1',
        'password' => 'New-secure-password1',
        'password_confirmation' => 'New-secure-password1',
    ])->assertOk();

    expect(Hash::check('New-secure-password1', $user->fresh()->password))->toBeTrue()
        ->and($user->tokens()->count())->toBe(0);
});

it('sends a reset notification without disclosing whether an account exists and resets a valid token', function () {
    Notification::fake();
    $user = passwordUser();

    $this->postJson('/api/auth/forgot-password', ['email' => $user->email])
        ->assertAccepted()
        ->assertJsonPath('message', 'If an account exists for this email, password reset instructions have been sent.');
    $this->postJson('/api/auth/forgot-password', ['email' => 'unknown@example.test'])
        ->assertAccepted();

    $token = null;
    Notification::assertSentTo($user, ResetPassword::class, function (ResetPassword $notification) use (&$token): bool {
        $token = $notification->token;

        return true;
    });

    $this->postJson('/api/auth/reset-password', [
        'email' => $user->email,
        'token' => $token,
        'password' => 'Reset-secure-password1',
        'password_confirmation' => 'Reset-secure-password1',
    ])->assertOk();

    expect(Hash::check('Reset-secure-password1', $user->fresh()->password))->toBeTrue();
});
