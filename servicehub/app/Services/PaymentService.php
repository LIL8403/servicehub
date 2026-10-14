<?php

namespace App\Services;

use App\Contracts\Payments\CamPayGateway;
use App\Enums\PaymentStatus;
use App\Enums\PayoutStatus;
use App\Enums\ServiceRequestStatus;
use App\Models\Payment;
use App\Models\Payout;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\Platform\PlatformSettingsService;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PaymentService
{
    public function __construct(
        private readonly CamPayGateway $camPay,
        private readonly ServiceRequestService $serviceRequests,
        private readonly PlatformSettingsService $platformSettings,
        private readonly AuditLogService $auditLogs,
    ) {}

    public function initiate(ServiceRequest $request, User $customer, string $phone, string $key, string $provider): Payment
    {
        abort_unless($request->customer_id === $customer->getKey(), 404);
        if ($request->status !== ServiceRequestStatus::PAYMENT_PENDING) {
            throw ValidationException::withMessages(['service_request' => ['Payment is not available in the current request state.']]);
        }

        $existing = Payment::query()->where('customer_id', $customer->getKey())->where('idempotency_key', $key)->first();
        if ($existing) {
            if ($existing->service_request_id !== $request->getKey()) {
                throw ValidationException::withMessages(['idempotency_key' => ['This idempotency key was used for another payment.']]);
            }

            return $existing;
        }

        // XAF has no fractional minor unit. The commission is snapshotted before
        // collection so later setting changes can never affect this payment.
        //
        // The quotation schema uses British spelling ('labour_total',
        // 'materials_total'), so we read those keys first and fall back
        // to the American spelling ('labor_amount') for tolerance with
        // any legacy records still using it.
        $labour = (float) (
            $request->quotation['labour_total']
            ?? $request->quotation['labor_amount']
            ?? 0
        );
        $materialsApproved = (($request->materials[0]['approval_status'] ?? null) === 'approved')
            ? (float) collect($request->materials)->sum('estimated_cost')
            : 0;
        $amount = (int) round($labour + $materialsApproved, 0, PHP_ROUND_HALF_UP);
        $commissionRate = $this->platformSettings->getCommissionRateSnapshot();
        $commissionAmount = $this->commissionFor($amount, $commissionRate);
        $externalReference = 'SH-' . Str::uuid();
        $payment = Payment::create([
            'service_request_id' => $request->getKey(),
            'customer_id' => $customer->getKey(),
            'amount' => $amount,
            'currency' => 'XAF',
            'status' => PaymentStatus::INITIATED,
            'provider' => 'campay',
            'provider_channel' => $provider,
            'idempotency_key' => $key,
            'external_reference' => $externalReference,
            'phone' => $phone,
            'events' => [['status' => PaymentStatus::INITIATED->value, 'occurred_at' => now()]],
            'commission_rate_snapshot' => $commissionRate,
            'commission_amount' => $commissionAmount,
            'artisan_gross_amount' => $amount,
            'artisan_net_amount' => $amount - $commissionAmount,
        ]);

        try {
            $result = $this->camPay->initiateCollection($amount, $phone, "ServiceHUB request {$request->getKey()}", $externalReference, $provider);
            $status = strtoupper($result['status']) === 'SUCCESSFUL' ? PaymentStatus::HELD : PaymentStatus::PROCESSING;
            $payment->update(['provider_reference' => $result['reference'], 'status' => $status, 'events' => [...$payment->events, ['status' => $status->value, 'occurred_at' => now(), 'provider_response' => $result['raw']]]]);
            $this->auditLogs->record('payment.collection_attempted', $customer->getKey(), 'payment', $payment->getKey(), [
                'provider' => 'campay',
                'request' => ['amount' => $amount, 'currency' => 'XAF', 'phone' => $phone, 'external_reference' => $externalReference],
                'response' => $result['raw'],
                'is_simulated' => false,
            ]);
            if ($status === PaymentStatus::HELD) {
                $this->bookVerifiedPayment($payment);
            }
        } catch (\Throwable $exception) {
            $providerResponse = $this->providerFailure($exception);
            $payment->update(['status' => PaymentStatus::FAILED, 'events' => [...$payment->events, ['status' => PaymentStatus::FAILED->value, 'occurred_at' => now(), 'reason' => $exception->getMessage()]]]);
            $this->auditLogs->record('payment.collection_failed', $customer->getKey(), 'payment', $payment->getKey(), [
                'provider' => 'campay',
                'request' => ['amount' => $amount, 'currency' => 'XAF', 'phone' => $phone, 'external_reference' => $externalReference],
                'provider_response' => $providerResponse,
                'is_simulated' => false,
            ]);
            throw $exception;
        }

        return $payment->fresh();
    }

    public function reconcile(Payment $payment, User $customer): Payment
    {
        abort_unless($payment->customer_id === $customer->getKey(), 404);
        if ($payment->provider_reference === null || ! in_array($payment->status, [PaymentStatus::INITIATED, PaymentStatus::PROCESSING], true)) {
            return $payment;
        }

        $result = $this->camPay->transactionStatus($payment->provider_reference);
        $payment = $this->applyProviderStatus($payment, $result);
        $this->auditLogs->record('payment.status_checked', $customer->getKey(), 'payment', $payment->getKey(), [
            'provider' => 'campay',
            'provider_response' => $result['raw'],
            'is_simulated' => false,
        ]);

        return $payment;
    }

    /** @param array{reference:string,status:string,raw:array<string,mixed>} $result */
    public function reconcileWebhook(string $reference, array $result): ?Payment
    {
        $payment = Payment::query()->where('provider_reference', $reference)->first();

        if (! $payment) {
            return null;
        }

        $this->assertWebhookMatches($payment->external_reference, $payment->amount, $payment->currency, $result['raw']);
        $this->auditLogs->record('payment.provider_webhook_received', null, 'payment', $payment->getKey(), [
            'provider' => 'campay',
            'provider_response' => $result['raw'],
            'is_simulated' => false,
        ]);

        return $this->applyProviderStatus($payment, $result);
    }

    /** @param array{reference:string,status:string,raw:array<string,mixed>} $result */
    public function reconcilePayoutWebhook(string $reference, array $result): ?Payout
    {
        $payout = Payout::query()->where('provider_reference', $reference)->first();
        if (! $payout || ! in_array($payout->status, [PayoutStatus::INITIATED, PayoutStatus::PROCESSING], true)) {
            return $payout;
        }

        $this->assertWebhookMatches($payout->external_reference, $payout->amount, $payout->currency, $result['raw']);
        $this->auditLogs->record('payout.provider_webhook_received', null, 'payout', $payout->getKey(), [
            'payment_id' => $payout->payment_id,
            'provider' => 'campay',
            'provider_response' => $result['raw'],
            'is_simulated' => false,
        ]);

        $nextPayoutStatus = match (strtoupper($result['status'])) {
            'SUCCESSFUL' => PayoutStatus::PAID,
            'FAILED' => PayoutStatus::FAILED,
            default => PayoutStatus::PROCESSING,
        };
        if ($payout->status === $nextPayoutStatus) {
            return $payout;
        }

        $payout->update(['status' => $nextPayoutStatus, 'events' => [...($payout->events ?? []), [
            'status' => $nextPayoutStatus->value,
            'occurred_at' => now(),
            'provider_response' => $result['raw'],
            'source' => 'provider_webhook',
        ]]]);
        $payment = Payment::query()->find($payout->payment_id);
        if ($payment && $payment->status === PaymentStatus::RELEASING) {
            $paymentStatus = $nextPayoutStatus === PayoutStatus::PAID ? PaymentStatus::RELEASED : ($nextPayoutStatus === PayoutStatus::FAILED ? PaymentStatus::HELD : PaymentStatus::RELEASING);
            if ($payment->status !== $paymentStatus) {
                $payment->update(['status' => $paymentStatus, 'events' => [...($payment->events ?? []), [
                    'status' => $paymentStatus->value,
                    'occurred_at' => now(),
                    'payout_id' => $payout->getKey(),
                    'provider_response' => $result['raw'],
                    'source' => 'provider_webhook',
                ]]]);
            }
        }

        return $payout->fresh();
    }

    public function releaseForCompletedRequest(ServiceRequest $serviceRequest, User $customer): Payout
    {
        abort_unless($serviceRequest->customer_id === $customer->getKey(), 404);
        $payment = $serviceRequest->payment_id
            ? Payment::query()->get()->first(fn(Payment $candidate) => $candidate->getKey() === $serviceRequest->payment_id)
            : null;
        if (! $payment) {
            throw ValidationException::withMessages(['payment' => ['A verified held payment is required before release.']]);
        }

        $existing = Payout::query()->where('payment_id', $payment->getKey())->first();
        if ($existing && $existing->status !== PayoutStatus::FAILED) {
            return $existing;
        }

        if ($payment->status !== PaymentStatus::HELD) {
            throw ValidationException::withMessages(['payment' => ['A verified held payment is required before release.']]);
        }

        $artisan = $serviceRequest->selectedArtisan()->firstOrFail();
        if (! $artisan->payout_phone) {
            throw ValidationException::withMessages(['payout' => ['The selected artisan has not configured a payout phone.']]);
        }

        $payout = $existing ?: Payout::create([
            'payment_id' => $payment->getKey(),
            'service_request_id' => $serviceRequest->getKey(),
            'artisan_profile_id' => $artisan->id,
            'amount' => $this->artisanNetAmount($payment),
            'currency' => $payment->currency,
            'status' => PayoutStatus::INITIATED,
            'provider' => 'campay',
            'external_reference' => 'SH-PO-' . Str::uuid(),
            'events' => [['status' => PayoutStatus::INITIATED->value, 'occurred_at' => now()]],
            'gross_amount' => $payment->artisan_gross_amount ?? $payment->amount,
            'commission_amount' => $payment->commission_amount ?? 0,
        ]);
        if ($existing) {
            $payout->update(['status' => PayoutStatus::INITIATED, 'events' => [...$payout->events, ['status' => PayoutStatus::INITIATED->value, 'occurred_at' => now(), 'reason' => 'Payout retry requested.']]]);
        }
        $payment->update(['status' => PaymentStatus::RELEASING, 'events' => [...$payment->events, ['status' => PaymentStatus::RELEASING->value, 'occurred_at' => now(), 'payout_id' => $payout->getKey()]]]);

        try {
            $result = $this->camPay->initiatePayout($payout->amount, $artisan->payout_phone, "ServiceHUB payout {$serviceRequest->getKey()}", $payout->external_reference);
            $payoutStatus = strtoupper($result['status']) === 'SUCCESSFUL' ? PayoutStatus::PAID : PayoutStatus::PROCESSING;
            $paymentStatus = $payoutStatus === PayoutStatus::PAID ? PaymentStatus::RELEASED : PaymentStatus::RELEASING;
            $payout->update(['provider_reference' => $result['reference'], 'status' => $payoutStatus, 'events' => [...$payout->events, ['status' => $payoutStatus->value, 'occurred_at' => now(), 'provider_response' => $result['raw']]]]);
            $payment->update(['status' => $paymentStatus, 'events' => [...$payment->fresh()->events, ['status' => $paymentStatus->value, 'occurred_at' => now(), 'payout_id' => $payout->getKey()]]]);
            $this->auditLogs->record('payment.payout_attempted', $customer->getKey(), 'payment', $payment->getKey(), [
                'provider' => 'campay',
                'request' => ['amount' => $payout->amount, 'currency' => $payment->currency, 'phone' => $artisan->payout_phone, 'external_reference' => $payout->external_reference],
                'response' => $result['raw'],
                'is_simulated' => false,
            ]);
        } catch (\Throwable $exception) {
            $providerResponse = $this->providerFailure($exception);
            $payout->update(['status' => PayoutStatus::FAILED, 'events' => [...$payout->events, ['status' => PayoutStatus::FAILED->value, 'occurred_at' => now(), 'reason' => $exception->getMessage()]]]);
            $payment->update(['status' => PaymentStatus::HELD, 'events' => [...$payment->fresh()->events, ['status' => PaymentStatus::HELD->value, 'occurred_at' => now(), 'reason' => 'Payout initiation failed.']]]);
            $this->auditLogs->record('payment.payout_failed', $customer->getKey(), 'payment', $payment->getKey(), [
                'provider' => 'campay',
                'request' => ['amount' => $payout->amount, 'currency' => $payment->currency, 'phone' => $artisan->payout_phone, 'external_reference' => $payout->external_reference],
                'provider_response' => $providerResponse,
                'is_simulated' => false,
            ]);
            throw $exception;
        }

        return $payout->fresh();
    }

    private function bookVerifiedPayment(Payment $payment): void
    {
        $serviceRequest = ServiceRequest::query()->findOrFail($payment->service_request_id);
        $this->serviceRequests->markBookedFromVerifiedPayment($serviceRequest, $payment->getKey());
    }

    /** @param array{reference:string,status:string,raw:array<string,mixed>} $result */
    private function applyProviderStatus(Payment $payment, array $result): Payment
    {
        $next = match (strtoupper($result['status'])) {
            'SUCCESSFUL' => PaymentStatus::HELD,
            'FAILED' => PaymentStatus::FAILED,
            default => PaymentStatus::PROCESSING,
        };

        if ($payment->status !== $next && in_array($payment->status, [PaymentStatus::INITIATED, PaymentStatus::PROCESSING], true)) {
            $payment->update(['status' => $next, 'events' => [...$payment->events, ['status' => $next->value, 'occurred_at' => now(), 'provider_response' => $result['raw'], 'source' => 'provider_status']]]);
            if ($next === PaymentStatus::HELD) {
                $this->bookVerifiedPayment($payment->fresh());
            }
        }

        return $payment->fresh();
    }

    private function artisanNetAmount(Payment $payment): int|float
    {
        // Payments created before commission snapshots were introduced are never
        // recalculated retrospectively.
        return $payment->artisan_net_amount ?? $payment->amount;
    }

    private function commissionFor(int $grossAmount, float $rate): int
    {
        return (int) round($grossAmount * $rate, 0, PHP_ROUND_HALF_UP);
    }

    /** @return array<string, mixed> */
    private function providerFailure(\Throwable $exception): array
    {
        if ($exception instanceof RequestException) {
            return [
                'status' => $exception->response->status(),
                'body' => $exception->response->json() ?? $exception->response->body(),
            ];
        }

        return ['error' => $exception->getMessage()];
    }

    /** @param array<string, mixed> $payload */
    private function assertWebhookMatches(string $externalReference, int|float $amount, string $currency, array $payload): void
    {
        if (($payload['external_reference'] ?? null) !== $externalReference
            || ! is_numeric($payload['amount'] ?? null)
            || (int) round((float) $payload['amount']) !== (int) round((float) $amount)
            || ($payload['currency'] ?? null) !== $currency
        ) {
            throw ValidationException::withMessages(['webhook' => ['CamPay callback does not match the recorded transaction.']]);
        }
    }
}
