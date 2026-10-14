<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\PaymentStatus;
use App\Enums\PayoutStatus;
use App\Http\Controllers\Controller;
use App\Services\AdminReportingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ReportingController extends Controller
{
    public function __construct(private readonly AdminReportingService $reports) {}

    public function dashboard(): JsonResponse
    {
        return response()->json(['dashboard' => $this->reports->dashboard()]);
    }

    public function payments(Request $request): JsonResponse
    {
        $payments = $this->reports->payments($request->validate($this->transactionRules(PaymentStatus::class)));

        return response()->json($this->paginated(
            $payments,
            collect($payments->items())->map($this->reports->paymentPayload(...))->values(),
            'payments',
        ));
    }

    public function payouts(Request $request): JsonResponse
    {
        $payouts = $this->reports->payouts($request->validate($this->transactionRules(PayoutStatus::class)));

        return response()->json($this->paginated(
            $payouts,
            collect($payouts->items())->map($this->reports->payoutPayload(...))->values(),
            'payouts',
        ));
    }

    public function serviceRequests(Request $request): JsonResponse
    {
        $requests = $this->reports->serviceRequests($request->validate([
            'status' => ['nullable', 'string', 'max:50'],
            'service_id' => ['nullable', 'string'],
            'customer_id' => ['nullable', 'string'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]));

        return response()->json($this->paginated(
            $requests,
            collect($requests->items())->map($this->reports->serviceRequestPayload(...))->values(),
            'service_requests',
        ));
    }

    public function auditLogs(Request $request): JsonResponse
    {
        $logs = $this->reports->auditLogs($request->validate([
            'event_type' => ['nullable', 'string', 'max:100'],
            'actor_id' => ['nullable', 'string'],
            'subject_type' => ['nullable', 'string', 'max:255'],
            'subject_id' => ['nullable', 'string'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]));

        return response()->json($this->paginated(
            $logs,
            collect($logs->items())->map($this->reports->auditLogPayload(...))->values(),
            'audit_logs',
        ));
    }

    private function transactionRules(string $statusEnum): array
    {
        return [
            'status' => ['nullable', Rule::enum($statusEnum)],
            'provider' => ['nullable', 'string', 'max:100'],
            'customer_id' => ['nullable', 'string'],
            'service_request_id' => ['nullable', 'string'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }

    private function paginated($paginator, $items, string $key): array
    {
        return [
            $key => $items,
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ];
    }
}
