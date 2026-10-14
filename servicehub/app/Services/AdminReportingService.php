<?php

namespace App\Services;

use App\Enums\AccountStatus;
use App\Enums\DisputeStatus;
use App\Enums\PaymentStatus;
use App\Enums\PayoutStatus;
use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\AuditLog;
use App\Models\Dispute;
use App\Models\Payment;
use App\Models\Payout;
use App\Models\ServiceRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class AdminReportingService
{
    public function __construct(private readonly AuditLogService $auditLogs) {}

    public function dashboard(): array
    {
        return [
            'users' => [
                'total' => User::query()->count(),
                'by_status' => $this->statusCounts(User::class, AccountStatus::cases(), 'account_status'),
            ],
            'artisans' => [
                'by_verification_status' => $this->statusCounts(Artisan::class, VerificationStatus::cases(), 'verification_status'),
            ],
            'service_requests' => [
                'total' => ServiceRequest::query()->count(),
                'by_status' => $this->statusCounts(ServiceRequest::class, ServiceRequestStatus::cases()),
            ],
            'payments' => [
                'total' => Payment::query()->count(),
                'by_status' => $this->statusCounts(Payment::class, PaymentStatus::cases()),
            ],
            'payouts' => [
                'total' => Payout::query()->count(),
                'by_status' => $this->statusCounts(Payout::class, PayoutStatus::cases()),
            ],
            'disputes' => [
                'total' => Dispute::query()->count(),
                'by_status' => $this->statusCounts(Dispute::class, DisputeStatus::cases()),
            ],
            // NEW: aggregated financial totals
            'revenue' => [
                'this_month' => $this->sumPaymentsBetween(
                    now()->startOfMonth(),
                    now(),
                ),
                'last_month' => $this->sumPaymentsBetween(
                    now()->subMonth()->startOfMonth(),
                    now()->subMonth()->endOfMonth(),
                ),
                'this_month_commission' => $this->sumCommissionBetween(
                    now()->startOfMonth(),
                    now(),
                ),
            ],

            // NEW: 30-day time series for the revenue + requests chart
            'daily_series' => $this->dailySeries(30),

            // NEW: recent activity (last 6 audit log events)
            'recent_activity' => $this->recentActivity(6),
        ];
    }

    public function payments(array $filters): LengthAwarePaginator
    {
        $query = Payment::query()->latest();
        $this->applyFilters($query, $filters);

        return $query->paginate($filters['per_page'] ?? 25);
    }

    public function payouts(array $filters): LengthAwarePaginator
    {
        $query = Payout::query()->latest();
        $this->applyFilters($query, $filters);

        return $query->paginate($filters['per_page'] ?? 25);
    }

    public function auditLogs(array $filters): LengthAwarePaginator
    {
        $query = AuditLog::query()->latest();

        // `event_type` supports partial matching (regex).
        if (isset($filters['event_type']) && $filters['event_type'] !== '') {
            $pattern = preg_quote($filters['event_type'], '/');
            $query->where('event_type', 'regex', "/{$pattern}/i");
        }

        // The other fields require exact matching.
        foreach (['actor_id', 'subject_type', 'subject_id'] as $field) {
            if (isset($filters[$field]) && $filters[$field] !== '') {
                $query->where($field, $filters[$field]);
            }
        }

        $this->applyDateFilters($query, $filters);

        return $query->paginate($filters['per_page'] ?? 25);
    }

    public function serviceRequests(array $filters): LengthAwarePaginator
    {
        $query = ServiceRequest::query()->latest();

        foreach (['status', 'service_id', 'customer_id'] as $field) {
            if (isset($filters[$field])) {
                $query->where($field, $filters[$field]);
            }
        }

        $this->applyDateFilters($query, $filters);

        return $query->paginate($filters['per_page'] ?? 25);
    }

    public function serviceRequestPayload(ServiceRequest $request): array
    {
        $customer = $request->customer_id
            ? User::query()->find($request->customer_id)
            : null;
        $service = $request->service_id
            ? \App\Models\Service::query()->find($request->service_id)
            : null;
        $artisanProfile = $request->selected_artisan_id
            ? \App\Models\Artisan::query()->find($request->selected_artisan_id)
            : null;
        $artisanUser = $artisanProfile
            ? User::query()->find($artisanProfile->user_id)
            : null;

        return [
            'id' => (string) $request->getKey(),
            'customer_id' => $request->customer_id,
            'customer_name' => $customer?->name,
            'service_id' => $request->service_id,
            'service_name' => $service?->name,
            'artisan_profile_id' => $request->selected_artisan_id,
            'artisan_name' => $artisanUser?->name,
            'description' => $request->description,
            'status' => $request->status instanceof \App\Enums\ServiceRequestStatus
                ? $request->status->value
                : (string) $request->status,
            'location_label' => $request->location['label'] ?? null,
            'formatted_address' => $request->formatted_address,
            'preferred_schedule' => $request->preferred_schedule,
            'urgency' => $request->urgency,
            'no_artisan_reason' => $request->no_artisan_reason,
            'matching_attempts' => $request->matching_attempts,
            'ai_assist_enabled' => $request->ai_assist_enabled,
            'image_attachments' => $request->image_attachments ?? [],
            'status_history' => $request->status_history ?? [],
            'selection_history' => $request->selection_history ?? [],
            'created_at' => $request->created_at,
            'updated_at' => $request->updated_at,
        ];
    }

    public function paymentPayload(Payment $payment): array
    {
        $customer = $payment->customer_id
            ? User::query()->find($payment->customer_id)
            : null;

        return [
            'id' => $payment->getKey(),
            'service_request_id' => $payment->service_request_id,
            'customer_id' => $payment->customer_id,
            'customer_name' => $customer?->name,
            'amount' => $payment->amount,
            'currency' => $payment->currency,
            'status' => $payment->status->value,
            'provider' => $payment->provider,
            'provider_reference' => $payment->provider_reference,
            'external_reference' => $payment->external_reference,
            'commission_rate_snapshot' => $payment->commission_rate_snapshot,
            'commission_amount' => $payment->commission_amount,
            'artisan_gross_amount' => $payment->artisan_gross_amount,
            'artisan_net_amount' => $payment->artisan_net_amount,
            'events' => $payment->events ?? [],
            'created_at' => $payment->created_at,
            'updated_at' => $payment->updated_at,
        ];
    }

    public function payoutPayload(Payout $payout): array
    {
        $artisan = $payout->artisan_profile_id
            ? \App\Models\Artisan::query()->find($payout->artisan_profile_id)
            : null;
        $artisanUser = $artisan
            ? User::query()->find($artisan->user_id)
            : null;

        return [
            'id' => $payout->getKey(),
            'payment_id' => $payout->payment_id,
            'service_request_id' => $payout->service_request_id,
            'artisan_profile_id' => $payout->artisan_profile_id,
            'artisan_name' => $artisanUser?->name,
            'amount' => $payout->amount,
            'gross_amount' => $payout->gross_amount,
            'commission_amount' => $payout->commission_amount,
            'currency' => $payout->currency,
            'status' => $payout->status->value,
            'provider' => $payout->provider,
            'provider_reference' => $payout->provider_reference,
            'external_reference' => $payout->external_reference,
            'events' => $payment->events ?? [],
            'created_at' => $payout->created_at,
            'updated_at' => $payout->updated_at,
        ];
    }

    public function auditLogPayload(AuditLog $auditLog): array
    {
        return [
            'id' => $auditLog->getKey(),
            'event_type' => $auditLog->event_type,
            'actor_id' => $auditLog->actor_id,
            'subject_type' => $auditLog->subject_type,
            'subject_id' => $auditLog->subject_id,
            'metadata' => $this->auditLogs->sanitize($auditLog->metadata ?? []),
            'created_at' => $auditLog->created_at,
        ];
    }

    /** @param class-string $model @param array<int, \BackedEnum> $statuses */
    private function statusCounts(string $model, array $statuses, string $field = 'status'): array
    {
        return collect($statuses)->mapWithKeys(fn(\BackedEnum $status) => [
            $status->value => $model::query()->where($field, $status->value)->count(),
        ])->all();
    }

    private function applyFilters($query, array $filters): void
    {
        foreach (['status', 'provider', 'customer_id', 'service_request_id'] as $field) {
            if (isset($filters[$field])) {
                $query->where($field, $filters[$field]);
            }
        }

        $this->applyDateFilters($query, $filters);
    }

    private function applyDateFilters($query, array $filters): void
    {
        if (isset($filters['from'])) {
            $query->where('created_at', '>=', Carbon::parse($filters['from'])->startOfDay());
        }

        if (isset($filters['to'])) {
            $query->where('created_at', '<=', Carbon::parse($filters['to'])->endOfDay());
        }
    }

    private function sumPaymentsBetween(Carbon $from, Carbon $to): int
    {
        return (int) Payment::query()
            ->where('created_at', '>=', $from)
            ->where('created_at', '<=', $to)
            ->get()
            ->sum(fn(Payment $p) => (int) ($p->amount ?? 0));
    }

    private function sumCommissionBetween(Carbon $from, Carbon $to): int
    {
        return (int) Payment::query()
            ->where('created_at', '>=', $from)
            ->where('created_at', '<=', $to)
            ->get()
            ->sum(fn(Payment $p) => (int) ($p->commission_amount ?? 0));
    }

    private function dailySeries(int $days): array
    {
        $result = [];
        $today = now()->startOfDay();

        for ($i = $days - 1; $i >= 0; $i--) {
            $day = $today->copy()->subDays($i);
            $next = $day->copy()->endOfDay();

            $payments = Payment::query()
                ->where('created_at', '>=', $day)
                ->where('created_at', '<=', $next)
                ->get();

            $requests = ServiceRequest::query()
                ->where('created_at', '>=', $day)
                ->where('created_at', '<=', $next)
                ->count();

            $result[] = [
                'date' => $day->toDateString(),
                'revenue' => (int) $payments->sum(fn(Payment $p) => (int) ($p->amount ?? 0)),
                'requests' => $requests,
            ];
        }

        return $result;
    }

    private function recentActivity(int $limit): array
    {
        return AuditLog::query()
            ->latest()
            ->limit($limit)
            ->get()
            ->map(function (AuditLog $log) {
                $actor = $log->actor_id
                    ? User::query()->find($log->actor_id)
                    : null;

                return [
                    'id' => $log->getKey(),
                    'event_type' => $log->event_type,
                    'actor_name' => $actor?->name,
                    'subject_type' => $log->subject_type,
                    'subject_id' => $log->subject_id,
                    'metadata' => $this->auditLogs->sanitize($log->metadata ?? []),
                    'created_at' => $log->created_at,
                ];
            })
            ->values()
            ->all();
    }
}
