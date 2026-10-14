<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\AccountStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateAccountStatusRequest;
use App\Models\User;
use App\Services\AdminUserManagementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserManagementController extends Controller
{
    public function __construct(private readonly AdminUserManagementService $users) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'role' => ['nullable', Rule::in(['customer', 'artisan', 'admin'])],
            'status' => ['nullable', Rule::enum(AccountStatus::class)],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);
        $users = $this->users->paginate($filters);

        return response()->json([
            'users' => collect($users->items())->map($this->userPayload(...))->values(),
            'meta' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
            ],
        ]);
    }

    public function updateStatus(UpdateAccountStatusRequest $request, User $user): JsonResponse
    {
        $user = $this->users->updateStatus(
            $user,
            AccountStatus::from($request->validated('status')),
            $request->validated('reason'),
            $request->user(),
        );

        return response()->json(['user' => $this->userPayload($user)]);
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => $user->getKey(),
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'roles' => $user->roles ?? [],
            'status' => $user->status->value,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ];
    }
}
