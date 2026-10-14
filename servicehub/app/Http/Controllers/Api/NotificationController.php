<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PlatformNotification;
use App\Services\AuditLogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(private readonly AuditLogService $auditLogs) {}

    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['per_page' => ['nullable', 'integer', 'min:1', 'max:100']]);
        $notifications = PlatformNotification::query()
            ->where('recipient_id', $request->user()->getKey())
            ->latest()
            ->paginate($data['per_page'] ?? 25);

        return response()->json([
            'notifications' => collect($notifications->items())->map($this->payload(...))->values(),
            'meta' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'per_page' => $notifications->perPage(),
                'total' => $notifications->total(),
                'unread_count' => PlatformNotification::query()
                    ->where('recipient_id', $request->user()->getKey())
                    ->whereNull('read_at')
                    ->count(),
            ],
        ]);
    }

    public function markRead(Request $request, PlatformNotification $notification): JsonResponse
    {
        abort_unless($notification->recipient_id === $request->user()->getKey(), 404);
        if ($notification->read_at === null) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json(['notification' => $this->payload($notification->fresh())]);
    }

    private function payload(PlatformNotification $notification): array
    {
        return [
            'id' => $notification->getKey(),
            'type' => $notification->type,
            'title' => $notification->title,
            'body' => $notification->body,
            'payload' => $this->auditLogs->sanitize($notification->payload ?? []),
            'read_at' => $notification->read_at,
            'created_at' => $notification->created_at,
        ];
    }
}
