<?php

namespace App\Services;

use App\Enums\PayoutStatus;
use App\Models\Artisan;
use App\Models\Payment;
use App\Models\Payout;
use App\Models\ServiceRequest;
use Illuminate\Support\Collection;
use App\Services\Platform\PlatformSettingsService;

/**
 * Aggregates payout records into totals and per-request detail for the
 * artisan earnings screen.
 *
 * The underlying schema:
 *  - Payment holds the money that came in from the customer and the
 *    commission snapshot (commission_amount, artisan_net_amount).
 *  - Payout holds one record per attempt to send funds to the artisan.
 *    Retry attempts create/update the same Payout (keyed by payment_id).
 */
class ArtisanEarningsService
{
    public function __construct(
        private readonly PlatformSettingsService $platformSettings,
    ) {}

    public function summary(Artisan $artisan): array
    {
        $payouts = Payout::query()
            ->where('artisan_profile_id', (string) $artisan->getKey())
            ->get();

        $pending = $this->sumByStatus($payouts, [PayoutStatus::INITIATED, PayoutStatus::PROCESSING]);
        $paid = $this->sumByStatus($payouts, [PayoutStatus::PAID]);
        $failed = $this->sumByStatus($payouts, [PayoutStatus::FAILED]);

        $commission = $payouts->sum(fn (Payout $p) => (float) ($p->commission_amount ?? 0));
        $gross = $payouts->sum(fn (Payout $p) => (float) ($p->gross_amount ?? 0));
        $net = $payouts->sum(fn (Payout $p) => (float) $p->amount);

        return [
            'pending' => (int) round($pending),
            'paid' => (int) round($paid),
            'failed' => (int) round($failed),
            'currency' => 'XAF',
            'payout_phone_configured' => filled($artisan->payout_phone),
            'commission_rate' => $this->platformSettings->getCommissionRateSnapshot(),
            'lifetime_gross' => (int) round($gross),
            'lifetime_net' => (int) round($net),
            'lifetime_commission' => (int) round($commission),
        ];
    }

    /**
     * Payout history, newest first, enriched with service + customer
     * so the tile can render a readable line without a second fetch.
     *
     * @return array{payouts: array<int,array<string,mixed>>, total:int, page:int, per_page:int}
     */
    public function payouts(Artisan $artisan, int $page = 1, int $perPage = 20): array
    {
        $query = Payout::query()
            ->where('artisan_profile_id', (string) $artisan->getKey())
            ->orderBy('created_at', 'desc');

        $total = (clone $query)->count();
        $payouts = $query->skip(($page - 1) * $perPage)->take($perPage)->get();

        // Enrich each payout with its service request context in one
        // query per collection (not per row).
        $requestIds = $payouts->pluck('service_request_id')->unique()->all();
        $requests = ServiceRequest::query()
            ->whereIn('_id', $requestIds)
            ->with(['service', 'customer'])
            ->get()
            ->keyBy(fn (ServiceRequest $sr) => (string) $sr->getKey());

        return [
            'payouts' => $payouts->map(function (Payout $p) use ($requests) {
                $request = $requests->get((string) $p->service_request_id);

                return [
                    'id' => (string) $p->getKey(),
                    'amount' => (int) round((float) $p->amount),
                    'currency' => $p->currency ?? 'XAF',
                    'status' => $p->status?->value ?? (string) $p->status,
                    'gross_amount' => (int) round((float) ($p->gross_amount ?? $p->amount)),
                    'commission_amount' => (int) round((float) ($p->commission_amount ?? 0)),
                    'request_id' => (string) $p->service_request_id,
                    'service_name' => $request?->service?->name ?? 'Service',
                    'customer_first_name' => $request?->customer?->first_name ?? '',
                    'created_at' => optional($p->created_at)->toIso8601String(),
                    'paid_at' => $this->paidAt($p),
                ];
            })->values()->all(),
            'total' => $total,
            'page' => $page,
            'per_page' => $perPage,
        ];
    }

    private function paidAt(Payout $payout): ?string
    {
        $events = collect($payout->events ?? []);
        $paidEvent = $events->firstWhere('status', PayoutStatus::PAID->value);

        return $paidEvent['occurred_at'] ?? null;
    }

    /** @param array<int,PayoutStatus> $statuses */
    private function sumByStatus(Collection $payouts, array $statuses): float
    {
        return (float) $payouts
            ->filter(fn (Payout $p) => in_array($p->status, $statuses, true))
            ->sum(fn (Payout $p) => (float) $p->amount);
    }
}