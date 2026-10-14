<?php

namespace App\Services;

use App\Contracts\Payments\CamPayGateway;
use App\Enums\DisputeStatus;
use App\Enums\PaymentStatus;
use App\Enums\PayoutStatus;
use App\Models\Dispute;
use App\Models\Payment;
use App\Models\Payout;
use App\Models\ResolutionReference;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\Payments\SimulatedCamPayGateway;
use Carbon\Carbon;
use Illuminate\Http\Client\RequestException;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class DisputeResolutionService
{
    public function __construct(
        private readonly CamPayGateway $camPay,
        private readonly SimulatedCamPayGateway $simulatedCamPay,
        private readonly AuditLogService $auditLogs,
        private readonly PlatformNotificationService $notifications,
    ) {}

    /** @param array<string, mixed> $data */
    public function initiate(Dispute $dispute, User $admin, array $data): Dispute
    {
        $this->assertMayResolve($dispute, $admin);
        $payment = $this->heldPayment($dispute);
        $amounts = $this->resolutionAmounts($payment, $data);
        $reference = (string) $data['resolution_reference'];
        $this->reserveReference($reference, $dispute);

        $resolution = [
            'decision' => $data['decision'],
            ...$amounts,
            'reason' => $data['reason'],
            'resolution_reference' => $reference,
            'initiated_by' => $admin->getKey(),
            'initiated_at' => now(),
            'is_simulated' => in_array($data['decision'], ['refund_customer', 'split_resolution'], true),
        ];

        if ($data['decision'] === 'hold') {
            $this->transitionDispute($dispute, DisputeStatus::UNDER_INVESTIGATION, $admin, $data['reason'], [
                'resolution_reference' => $reference,
                'decision' => 'hold',
            ]);
            $dispute->update(['resolution_reference' => $reference, 'resolution' => [...$resolution, 'status' => 'held_for_investigation']]);
            $this->audit($admin, $dispute, $payment, 'dispute.resolution_hold', $resolution);
            $this->setReferenceStatus($reference, 'reserved', 'held_for_investigation');

            return $dispute->fresh();
        }

        $pending = [...$resolution, 'expires_at' => now()->addMinutes(15)];
        $this->transitionDispute($dispute, DisputeStatus::PENDING_EXECUTION, $admin, 'Financial resolution awaiting confirmation.', [
            'resolution_reference' => $reference,
            'decision' => $data['decision'],
        ]);
        $dispute->update(['resolution_reference' => $reference, 'pending_resolution' => $pending]);
        $this->audit($admin, $dispute, $payment, 'dispute.resolution_initiated', $pending);

        return $dispute->fresh();
    }

    public function confirm(Dispute $dispute, User $admin): Dispute
    {
        $dispute = $dispute->fresh();
        if ($dispute->status !== DisputeStatus::PENDING_EXECUTION || ! $dispute->pending_resolution) {
            throw ValidationException::withMessages(['dispute' => ['This dispute has no pending financial resolution.']]);
        }
        if (Carbon::parse($dispute->pending_resolution['expires_at'])->isPast()) {
            return $this->expire($dispute, 'Confirmation window expired.');
        }

        $payment = $this->heldPayment($dispute);
        $resolution = $dispute->pending_resolution;
        $this->claimReference($resolution['resolution_reference'], 'executing');
        $this->audit($admin, $dispute, $payment, 'dispute.resolution_confirmation_requested', $resolution);

        return match ($resolution['decision']) {
            'refund_customer' => $this->executeSimulatedRefund($dispute, $payment, $admin, $resolution),
            'release_artisan' => $this->executeRelease($dispute, $payment, $admin, $resolution, false),
            'split_resolution' => $this->executeSplit($dispute, $payment, $admin, $resolution),
            default => throw new RuntimeException('Unsupported financial resolution decision.'),
        };
    }

    public function cancel(Dispute $dispute, User $admin, string $reason): Dispute
    {
        if ($dispute->status !== DisputeStatus::PENDING_EXECUTION || ! $dispute->pending_resolution) {
            throw ValidationException::withMessages(['dispute' => ['Only a pending resolution can be cancelled.']]);
        }

        $payment = $this->payment($dispute);
        $pending = $dispute->pending_resolution;
        $this->claimReference($pending['resolution_reference'], 'cancelled');
        $this->transitionDispute($dispute, DisputeStatus::UNDER_REVIEW, $admin, $reason, ['resolution_reference' => $pending['resolution_reference'], 'action' => 'cancelled']);
        $dispute->update(['pending_resolution' => null, 'resolution' => [...$pending, 'status' => 'cancelled', 'cancelled_at' => now(), 'cancelled_by' => $admin->getKey(), 'cancellation_reason' => $reason]]);
        $this->audit($admin, $dispute, $payment, 'dispute.resolution_cancelled', [...$pending, 'reason' => $reason]);
        $this->notifications->notifyUser($pending['initiated_by'], 'dispute_resolution_cancelled', 'Dispute resolution cancelled', "Resolution for dispute {$dispute->getKey()} was cancelled: {$reason}", ['dispute_id' => $dispute->getKey()]);

        return $dispute->fresh();
    }

    public function reconcile(Dispute $dispute, User $admin, string $notes): Dispute
    {
        if ($dispute->status !== DisputeStatus::RECONCILIATION_REQUIRED) {
            throw ValidationException::withMessages(['dispute' => ['This dispute does not require reconciliation.']]);
        }
        $payment = $this->payment($dispute);
        if ($payment->status !== PaymentStatus::RECONCILIATION_REQUIRED) {
            throw ValidationException::withMessages(['payment' => ['Payment reconciliation state is inconsistent.']]);
        }

        $payout = Payout::query()->where('payment_id', $payment->getKey())->first();
        if ($payout && $payout->status === PayoutStatus::FAILED) {
            $payout->update(['status' => PayoutStatus::PAID, 'events' => [...($payout->events ?? []), [
                'status' => PayoutStatus::PAID->value,
                'occurred_at' => now(),
                'source' => 'manual_reconciliation',
            ]]]);
        }
        $payment = $this->paymentTransition($payment, PaymentStatus::PARTIALLY_REFUNDED, ['source' => 'manual_reconciliation']);
        $this->transitionDispute($dispute, DisputeStatus::RESOLVED, $admin, $notes, ['action' => 'manual_reconciliation_completed']);
        $dispute->update(['resolution' => [...($dispute->resolution ?? []), 'status' => 'reconciled', 'reconciled_at' => now(), 'reconciled_by' => $admin->getKey()]]);
        $this->audit($admin, $dispute, $payment, 'dispute.reconciliation_completed', ['notes' => $notes, 'resolution_reference' => $dispute->resolution_reference]);
        $this->setReferenceStatus($dispute->resolution_reference, 'reconciliation_required', 'reconciled');
        $this->notifyParticipants($dispute, $payment, $dispute->resolution ?? []);

        return $dispute->fresh();
    }

    public function expireDueResolutions(): int
    {
        $expired = Dispute::query()->get()->filter(function (Dispute $dispute): bool {
            return $dispute->status === DisputeStatus::PENDING_EXECUTION
                && isset($dispute->pending_resolution['expires_at'])
                && Carbon::parse($dispute->pending_resolution['expires_at'])->isPast();
        });

        $expired->each(fn (Dispute $dispute) => $this->expire($dispute, 'Confirmation window expired.'));

        return $expired->count();
    }

    private function executeSimulatedRefund(Dispute $dispute, Payment $payment, User $admin, array $resolution): Dispute
    {
        $payment = $this->paymentTransition($payment, PaymentStatus::REFUNDING, ['is_simulated' => true, 'resolution_reference' => $resolution['resolution_reference']]);
        $result = $this->simulatedCamPay->initiateRefund((int) $resolution['customer_refund_amount'], (string) ($payment->provider_reference ?? $payment->external_reference), $resolution['resolution_reference']);
        $this->audit($admin, $dispute, $payment, 'dispute.simulated_refund_attempted', [...$resolution, 'provider_response' => $result['raw']]);

        if (strtoupper($result['status']) !== 'SUCCESSFUL') {
            return $this->revertBeforeExecutionFailure($dispute, $payment, $admin, $resolution, 'Simulated customer refund failed.', $result['raw']);
        }

        $payment = $this->paymentTransition($payment, PaymentStatus::REFUNDED, ['is_simulated' => true, 'provider_response' => $result['raw'], 'resolution_reference' => $resolution['resolution_reference']]);

        return $this->finalize($dispute, $payment, $admin, $resolution, ['refund' => $result['raw']]);
    }

    private function executeRelease(Dispute $dispute, Payment $payment, User $admin, array $resolution, bool $simulated): Dispute
    {
        $outcome = $this->executePayout($dispute, $payment, $resolution, $simulated);
        if (! $outcome['success']) {
            return $this->revertBeforeExecutionFailure($dispute, $payment->fresh(), $admin, $resolution, 'Artisan payout failed.', $outcome['response']);
        }

        $payment = $this->paymentTransition($payment->fresh(), PaymentStatus::RELEASED, [
            'is_simulated' => $simulated,
            'provider_response' => $outcome['response'],
            'resolution_reference' => $resolution['resolution_reference'],
        ]);

        return $this->finalize($dispute, $payment, $admin, $resolution, ['payout' => $outcome['response']]);
    }

    private function executeSplit(Dispute $dispute, Payment $payment, User $admin, array $resolution): Dispute
    {
        $payment = $this->paymentTransition($payment, PaymentStatus::REFUNDING, ['is_simulated' => true, 'resolution_reference' => $resolution['resolution_reference']]);
        $refund = $this->simulatedCamPay->initiateRefund((int) $resolution['customer_refund_amount'], (string) ($payment->provider_reference ?? $payment->external_reference), $resolution['resolution_reference']);
        $this->audit($admin, $dispute, $payment, 'dispute.simulated_split_refund_attempted', [...$resolution, 'provider_response' => $refund['raw']]);
        if (strtoupper($refund['status']) !== 'SUCCESSFUL') {
            return $this->revertBeforeExecutionFailure($dispute, $payment, $admin, $resolution, 'Simulated split refund failed.', $refund['raw']);
        }

        $outcome = $this->executePayout($dispute, $payment->fresh(), $resolution, true);
        if (! $outcome['success']) {
            return $this->reconciliationRequired($dispute, $payment->fresh(), $admin, $resolution, $refund['raw'], $outcome['response']);
        }

        $payment = $this->paymentTransition($payment->fresh(), PaymentStatus::PARTIALLY_REFUNDED, [
            'is_simulated' => true,
            'refund_provider_response' => $refund['raw'],
            'payout_provider_response' => $outcome['response'],
            'resolution_reference' => $resolution['resolution_reference'],
        ]);

        return $this->finalize($dispute, $payment, $admin, $resolution, ['refund' => $refund['raw'], 'payout' => $outcome['response']]);
    }

    /** @return array{success: bool, response: array<string, mixed>} */
    private function executePayout(Dispute $dispute, Payment $payment, array $resolution, bool $simulated): array
    {
        $request = ServiceRequest::query()->find($dispute->service_request_id);
        $artisan = $request?->selectedArtisan()->first();
        if (! $request || ! $artisan || ! $artisan->payout_phone) {
            return ['success' => false, 'response' => ['error' => 'Artisan payout phone is not configured.', 'is_simulated' => $simulated]];
        }

        $payout = Payout::query()->where('payment_id', $payment->getKey())->first();
        if (! $payout) {
            $payout = Payout::create([
                'payment_id' => $payment->getKey(),
                'service_request_id' => $request->getKey(),
                'artisan_profile_id' => $artisan->getKey(),
                'amount' => $resolution['artisan_net_amount'],
                'gross_amount' => $resolution['artisan_gross_release'],
                'commission_amount' => $resolution['commission_amount'],
                'currency' => $payment->currency,
                'status' => PayoutStatus::INITIATED,
                'provider' => $simulated ? 'campay_simulated' : 'campay',
                'external_reference' => 'SH-DR-'.$resolution['resolution_reference'],
                'events' => [[
                    'status' => PayoutStatus::INITIATED->value,
                    'occurred_at' => now(),
                    'is_simulated' => $simulated,
                ]],
            ]);
        }

        $payment = $this->paymentTransition($payment, PaymentStatus::RELEASING, ['is_simulated' => $simulated, 'payout_id' => $payout->getKey(), 'resolution_reference' => $resolution['resolution_reference']]);
        try {
            $gateway = $simulated ? $this->simulatedCamPay : $this->camPay;
            $result = $gateway->initiatePayout((int) $payout->amount, $artisan->payout_phone, "ServiceHUB dispute payout {$dispute->getKey()}", $payout->external_reference);
        } catch (\Throwable $exception) {
            $response = [...$this->providerFailure($exception), 'is_simulated' => $simulated];
            $payout->update(['status' => PayoutStatus::FAILED, 'events' => [...($payout->events ?? []), ['status' => PayoutStatus::FAILED->value, 'occurred_at' => now(), 'provider_response' => $response]]]);

            return ['success' => false, 'response' => $response];
        }

        if (strtoupper($result['status']) !== 'SUCCESSFUL') {
            $payout->update(['provider_reference' => $result['reference'], 'status' => PayoutStatus::FAILED, 'events' => [...($payout->events ?? []), ['status' => PayoutStatus::FAILED->value, 'occurred_at' => now(), 'provider_response' => $result['raw']]]]);

            return ['success' => false, 'response' => $result['raw']];
        }

        $payout->update(['provider_reference' => $result['reference'], 'status' => PayoutStatus::PAID, 'events' => [...($payout->events ?? []), ['status' => PayoutStatus::PAID->value, 'occurred_at' => now(), 'provider_response' => $result['raw']]]]);

        return ['success' => true, 'response' => $result['raw']];
    }

    private function reconciliationRequired(Dispute $dispute, Payment $payment, User $admin, array $resolution, array $refund, array $payout): Dispute
    {
        $payment = $this->paymentTransition($payment, PaymentStatus::RECONCILIATION_REQUIRED, [
            'is_simulated' => true,
            'refund_provider_response' => $refund,
            'payout_provider_response' => $payout,
            'resolution_reference' => $resolution['resolution_reference'],
        ]);
        $this->transitionDispute($dispute, DisputeStatus::RECONCILIATION_REQUIRED, $admin, 'Simulated refund succeeded but simulated payout failed. Manual reconciliation is required.', ['resolution_reference' => $resolution['resolution_reference']]);
        $dispute->update(['pending_resolution' => null, 'resolution' => [...$resolution, 'status' => 'reconciliation_required', 'provider_operations' => ['refund' => $refund, 'payout' => $payout]]]);
        $this->audit($admin, $dispute, $payment, 'dispute.reconciliation_required', [...$resolution, 'refund_provider_response' => $refund, 'payout_provider_response' => $payout]);
        $this->completeReference($resolution['resolution_reference'], 'reconciliation_required');
        $this->notifications->notifyAdmins('dispute_reconciliation_required', 'Dispute reconciliation required', "SIMULATED — no real funds moved. Dispute {$dispute->getKey()} requires reconciliation after a simulated refund succeeded and simulated payout failed.", ['dispute_id' => $dispute->getKey(), 'is_simulated' => true]);

        return $dispute->fresh();
    }

    private function revertBeforeExecutionFailure(Dispute $dispute, Payment $payment, User $admin, array $resolution, string $message, array $providerResponse): Dispute
    {
        $payment = $this->paymentTransition($payment, PaymentStatus::HELD, ['reason' => $message, 'provider_response' => $providerResponse, 'resolution_reference' => $resolution['resolution_reference']]);
        $this->transitionDispute($dispute, DisputeStatus::UNDER_REVIEW, $admin, $message, ['resolution_reference' => $resolution['resolution_reference']]);
        $dispute->update(['pending_resolution' => null, 'resolution' => [...$resolution, 'status' => 'failed_before_execution', 'provider_response' => $providerResponse]]);
        $this->audit($admin, $dispute, $payment, 'dispute.resolution_execution_failed', [...$resolution, 'provider_response' => $providerResponse]);
        $this->completeReference($resolution['resolution_reference'], 'failed_before_execution');
        $this->notifications->notifyAdmins('dispute_resolution_failed', 'Dispute resolution failed safely', "Dispute {$dispute->getKey()} returned to review. {$message}", ['dispute_id' => $dispute->getKey()]);

        return $dispute->fresh();
    }

    private function finalize(Dispute $dispute, Payment $payment, User $admin, array $resolution, array $providerOperations): Dispute
    {
        $this->transitionDispute($dispute, DisputeStatus::RESOLVED, $admin, 'Financial resolution executed.', ['resolution_reference' => $resolution['resolution_reference']]);
        $dispute->update(['pending_resolution' => null, 'resolution' => [...$resolution, 'status' => 'executed', 'executed_at' => now(), 'confirmed_by' => $admin->getKey(), 'provider_operations' => $providerOperations]]);
        $this->audit($admin, $dispute, $payment, 'dispute.resolution_executed', [...$resolution, 'provider_operations' => $providerOperations]);
        $this->completeReference($resolution['resolution_reference'], 'executed');
        $this->notifyParticipants($dispute, $payment, $resolution);

        return $dispute->fresh();
    }

    private function expire(Dispute $dispute, string $reason): Dispute
    {
        $pending = $dispute->pending_resolution;
        if (! $pending || $dispute->status !== DisputeStatus::PENDING_EXECUTION) {
            return $dispute;
        }
        $payment = $this->payment($dispute);
        if (! $this->claimReference($pending['resolution_reference'], 'expired', false)) {
            return $dispute->fresh();
        }
        $dispute->update([
            'status' => DisputeStatus::UNDER_REVIEW,
            'pending_resolution' => null,
            'resolution' => [...$pending, 'status' => 'expired', 'expired_at' => now(), 'expiration_reason' => $reason],
            'status_history' => [...($dispute->status_history ?? []), ['status' => DisputeStatus::UNDER_REVIEW->value, 'occurred_at' => now(), 'reason' => $reason]],
        ]);
        $this->auditLogs->record('dispute.resolution_expired', $pending['initiated_by'] ?? null, 'dispute', $dispute->getKey(), $this->auditData($dispute, $payment, $pending));
        if (! empty($pending['initiated_by'])) {
            $this->notifications->notifyUser($pending['initiated_by'], 'dispute_resolution_expired', 'Dispute resolution expired', "Resolution for dispute {$dispute->getKey()} expired after 15 minutes and returned to review.", ['dispute_id' => $dispute->getKey()]);
        }

        return $dispute->fresh();
    }

    private function assertMayResolve(Dispute $dispute, User $admin): void
    {
        if ($dispute->status !== DisputeStatus::UNDER_REVIEW) {
            throw ValidationException::withMessages(['dispute' => ['Only a dispute under review can receive a resolution.']]);
        }
        if ((string) $dispute->reporter_id === (string) $admin->getKey()) {
            throw ValidationException::withMessages(['dispute' => ['The reporting user cannot resolve their own dispute.']]);
        }
    }

    private function heldPayment(Dispute $dispute): Payment
    {
        $payment = $this->payment($dispute);
        if ($payment->status !== PaymentStatus::HELD) {
            throw ValidationException::withMessages(['payment' => ['Only a held payment can be financially resolved.']]);
        }

        return $payment;
    }

    private function payment(Dispute $dispute): Payment
    {
        return Payment::query()->findOrFail($dispute->payment_id);
    }

    /** @param array<string, mixed> $data @return array<string, int|float> */
    private function resolutionAmounts(Payment $payment, array $data): array
    {
        $held = $this->wholeXaf($payment->amount, 'payment');
        $refund = $this->wholeXaf($data['customer_refund_amount'], 'customer_refund_amount');
        $gross = $this->wholeXaf($data['artisan_gross_release'], 'artisan_gross_release');
        $decision = $data['decision'];

        $valid = match ($decision) {
            'refund_customer' => $refund === $held && $gross === 0,
            'release_artisan' => $refund === 0 && $gross === $held,
            'split_resolution' => $refund + $gross === $held,
            'hold' => $refund === 0 && $gross === 0,
            default => false,
        };
        if (! $valid) {
            throw ValidationException::withMessages(['resolution' => ['Amounts do not match the permitted resolution outcome.']]);
        }

        $rate = $payment->commission_rate_snapshot;
        // Legacy payments have no snapshot and must never receive a retroactive commission.
        $rate = $rate === null ? 0.0 : (float) $rate;
        $commission = in_array($decision, ['release_artisan', 'split_resolution'], true)
            ? (int) round($gross * $rate, 0, PHP_ROUND_HALF_UP)
            : 0;

        return [
            'held_amount' => $held,
            'customer_refund_amount' => $refund,
            'artisan_gross_release' => $gross,
            'commission_rate_used' => $rate,
            'commission_amount' => $commission,
            'artisan_net_amount' => $gross - $commission,
        ];
    }

    private function wholeXaf(mixed $amount, string $field): int
    {
        if (! is_numeric($amount) || (float) $amount < 0 || abs((float) $amount - round((float) $amount)) > 0.000001) {
            throw ValidationException::withMessages([$field => ['Amounts must be non-negative whole XAF values.']]);
        }

        return (int) round((float) $amount);
    }

    private function reserveReference(string $reference, Dispute $dispute): void
    {
        try {
            ResolutionReference::create(['reference' => $reference, 'dispute_id' => $dispute->getKey(), 'status' => 'reserved']);
        } catch (\Throwable $exception) {
            if ((int) $exception->getCode() === 11000) {
                throw ValidationException::withMessages(['resolution_reference' => ['This resolution reference has already been used.']]);
            }

            throw $exception;
        }
    }

    private function claimReference(string $reference, string $nextStatus, bool $throwOnFailure = true): bool
    {
        $claimed = ResolutionReference::query()
            ->where('reference', $reference)
            ->where('status', 'reserved')
            ->update(['status' => $nextStatus, 'claimed_at' => now()]);

        if ($claimed) {
            return true;
        }
        if ($throwOnFailure) {
            throw ValidationException::withMessages(['resolution_reference' => ['This resolution is already being processed or is no longer pending.']]);
        }

        return false;
    }

    private function completeReference(string $reference, string $status): void
    {
        ResolutionReference::query()->where('reference', $reference)->where('status', 'executing')->update([
            'status' => $status,
            'completed_at' => now(),
        ]);
    }

    private function setReferenceStatus(string $reference, string $fromStatus, string $toStatus): void
    {
        ResolutionReference::query()->where('reference', $reference)->where('status', $fromStatus)->update([
            'status' => $toStatus,
            'completed_at' => now(),
        ]);
    }

    /** @param array<string, mixed> $context */
    private function paymentTransition(Payment $payment, PaymentStatus $status, array $context = []): Payment
    {
        $payment->update(['status' => $status, 'events' => [...($payment->events ?? []), [
            'status' => $status->value,
            'occurred_at' => now(),
            ...$context,
        ]]]);

        return $payment->fresh();
    }

    /** @param array<string, mixed> $context */
    private function transitionDispute(Dispute $dispute, DisputeStatus $status, User $actor, string $message, array $context = []): void
    {
        $dispute->update([
            'status' => $status,
            'updates' => [...($dispute->updates ?? []), ['message' => $message, 'submitted_at' => now(), 'submitted_by' => $actor->getKey(), 'submitted_by_role' => 'admin']],
            'status_history' => [...($dispute->status_history ?? []), ['status' => $status->value, 'occurred_at' => now(), 'actor_id' => $actor->getKey(), ...$context]],
        ]);
    }

    /** @param array<string, mixed> $metadata */
    private function audit(User $admin, Dispute $dispute, Payment $payment, string $event, array $metadata): void
    {
        $this->auditLogs->record($event, $admin->getKey(), 'dispute', $dispute->getKey(), $this->auditData($dispute, $payment, $metadata));
    }

    /** @param array<string, mixed> $metadata @return array<string, mixed> */
    private function auditData(Dispute $dispute, Payment $payment, array $metadata): array
    {
        return ['dispute_id' => $dispute->getKey(), 'payment_id' => $payment->getKey(), ...$metadata];
    }

    /** @param array<string, mixed> $resolution */
    private function notifyParticipants(Dispute $dispute, Payment $payment, array $resolution): void
    {
        $request = ServiceRequest::query()->findOrFail($dispute->service_request_id);
        $decision = (string) ($resolution['decision'] ?? 'resolution');
        $timestamp = now()->toIso8601String();
        $customerAmount = (int) ($resolution['customer_refund_amount'] ?? 0);
        $artisanAmount = (int) ($resolution['artisan_net_amount'] ?? 0);
        $simulated = (bool) ($resolution['is_simulated'] ?? false);
        $notice = $simulated ? ' SIMULATED — no real funds moved.' : '';
        $this->notifications->notifyUser($request->customer_id, 'dispute_resolution_completed', 'Dispute resolution completed', "Outcome: {$decision}. Customer amount: {$customerAmount} XAF. {$timestamp}.{$notice}", ['dispute_id' => $dispute->getKey(), 'is_simulated' => $simulated]);
        if ($artisan = $request->selectedArtisan()->first()) {
            $this->notifications->notifyUser($artisan->user_id, 'dispute_resolution_completed', 'Dispute resolution completed', "Outcome: {$decision}. Artisan net amount: {$artisanAmount} XAF. {$timestamp}.{$notice}", ['dispute_id' => $dispute->getKey(), 'is_simulated' => $simulated]);
        }
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
}
