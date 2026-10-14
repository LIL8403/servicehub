<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\User\BecomeArtisanRequest;
use App\Http\Requests\User\SwitchRoleRequest;
use App\Services\UserRoleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserRoleController extends Controller
{
    public function __construct(private readonly UserRoleService $roles) {}

    public function roles(Request $request): JsonResponse
    {
        return response()->json($this->payload($request->user()));
    }

    public function switchRole(SwitchRoleRequest $request): JsonResponse
    {
        $user = $this->roles->switchRole($request->user(), $request->validated('role'));

        return response()->json($this->payload($user));
    }

    public function becomeArtisan(BecomeArtisanRequest $request): JsonResponse
    {
        $artisan = $this->roles->becomeArtisan($request->user(), $request->validated());
        $user = $request->user()->fresh();

        return response()->json([
            ...$this->payload($user),
            'artisan' => $artisan,
        ], 201);
    }

    private function payload($user): array
    {
        return ['roles' => $user->roles ?? [], 'active_role' => $user->active_role];
    }
}
