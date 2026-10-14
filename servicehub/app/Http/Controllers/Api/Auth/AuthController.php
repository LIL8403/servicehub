<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ArtisanRegistrationRequest;
use App\Http\Requests\Auth\ChangePasswordRequest;
use App\Http\Requests\Auth\CustomerRegistrationRequest;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private readonly AuthService $authService
    ) {}

    public function registerCustomer(
        CustomerRegistrationRequest $request
    ): JsonResponse {
        $result = $this->authService->registerCustomer(
            $request->validated()
        );

        return response()->json([
            'message' => 'Customer registered successfully.',
            'user' => $result['user'],
            'token' => $result['token'],
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login(
            $request->validated()
        );

        return response()->json([
            'message' => 'Login successful.',
            'user' => $result['user'],
            'token' => $result['token'],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout(
            $request->user()
        );

        return response()->json([
            'message' => 'Logout successful.',
        ]);
    }

    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $this->authService->changePassword($request->user(), $request->validated('password'));

        return response()->json(['message' => 'Password changed. Please sign in again.']);
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $this->authService->requestPasswordReset($request->validated('email'));

        return response()->json(['message' => 'If an account exists for this email, password reset instructions have been sent.'], 202);
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $this->authService->resetPassword($request->validated());

        return response()->json(['message' => 'Password reset successfully. Please sign in.']);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'user' => $user,
        ]);
    }

    public function registerArtisan(
        ArtisanRegistrationRequest $request
    ): JsonResponse {
        $result = $this->authService->registerArtisan(
            $request->validated()
        );

        return response()->json([
            'message' => 'Artisan registered successfully. Your profile is pending verification.',
            'user' => $result['user'],
            'artisan_profile' => $result['artisan_profile'],
            'token' => $result['token'],
        ], 201);
    }
}
