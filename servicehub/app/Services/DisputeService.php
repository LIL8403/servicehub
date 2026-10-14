<?php

namespace App\Services;

use App\Enums\DisputeStatus;
use App\Enums\PaymentStatus;
use App\Enums\ServiceRequestStatus;
use App\Models\Dispute;
use App\Models\Payment;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class DisputeService
{
    public function open(ServiceRequest $request, User $reporter, array $data): Dispute
    {
        $role = $this->participantRole($request, $reporter);
        if (in_array($request->status, [ServiceRequestStatus::CREATED, ServiceRequestStatus::CANCELLED, ServiceRequestStatus::DISPUTED], true)) {
            throw ValidationException::withMessages(['service_request' => ['A dispute cannot be opened in the current request state.']]);
        }
        if ($this->activeDispute($request)) {
            throw ValidationException::withMessages(['service_request' => ['An active dispute already exists for this service request.']]);
        }

        $dispute = Dispute::create([
            ...$data,
            'evidence' => $this->evidence($data['evidence'] ?? [], $reporter),
            'updates' => [],
            'service_request_id' => $request->getKey(),
            'payment_id' => $request->payment_id,
            'reporter_id' => $reporter->getKey(),
            'reporter_role' => $role,
            'prior_request_status' => $request->status->value,
            'status' => DisputeStatus::OPENED,
            'status_history' => [$this->history(DisputeStatus::OPENED, $reporter)],
        ]);

        $request->update([
            'status' => ServiceRequestStatus::DISPUTED,
            'status_history' => [...($request->status_history ?? []), [
                'status' => ServiceRequestStatus::DISPUTED->value,
                'occurred_at' => now(),
                'actor_id' => $reporter->getKey(),
                'dispute_id' => $dispute->getKey(),
            ]],
        ]);

        $this->recordPaymentDisputeHold($request, $dispute->getKey());

        return $dispute->fresh();
    }

    public function addEvidence(Dispute $dispute, User $participant, array $data): Dispute
    {
        $request = ServiceRequest::query()->findOrFail($dispute->service_request_id);
        $this->participantRole($request, $participant);
        if (! in_array($dispute->status, [DisputeStatus::OPENED, DisputeStatus::UNDER_REVIEW, DisputeStatus::AWAITING_INFORMATION, DisputeStatus::UNDER_INVESTIGATION], true)) {
            throw ValidationException::withMessages(['dispute' => ['Evidence cannot be added to a closed dispute.']]);
        }

        $status = $dispute->status === DisputeStatus::AWAITING_INFORMATION ? DisputeStatus::UNDER_REVIEW : $dispute->status;
        $history = $dispute->status_history ?? [];
        if ($status !== $dispute->status) {
            $history[] = $this->history($status, $participant, ['reason' => 'Requested information received.']);
        }
        $dispute->update([
            'status' => $status,
            'evidence' => [...($dispute->evidence ?? []), ...$this->evidence($data['evidence'] ?? [], $participant)],
            'updates' => [...($dispute->updates ?? []), ['message' => $data['message'], 'submitted_at' => now(), 'submitted_by' => $participant->getKey()]],
            'status_history' => $history,
        ]);

        return $dispute->fresh();
    }

    public function startReview(Dispute $dispute, User $admin, string $notes): Dispute
    {
        if (! in_array($dispute->status, [DisputeStatus::OPENED, DisputeStatus::AWAITING_INFORMATION, DisputeStatus::UNDER_INVESTIGATION], true)) {
            throw ValidationException::withMessages(['dispute' => ['Only an opened, information-pending, or investigated dispute can enter review.']]);
        }

        return $this->transition($dispute, DisputeStatus::UNDER_REVIEW, $admin, $notes);
    }

    public function awaitInformation(Dispute $dispute, User $admin, string $notes): Dispute
    {
        if ($dispute->status !== DisputeStatus::UNDER_REVIEW) {
            throw ValidationException::withMessages(['dispute' => ['Only a dispute under review can await information.']]);
        }

        return $this->transition($dispute, DisputeStatus::AWAITING_INFORMATION, $admin, $notes);
    }

    public function investigate(Dispute $dispute, User $admin, string $notes): Dispute
    {
        if ($dispute->status !== DisputeStatus::UNDER_REVIEW) {
            throw ValidationException::withMessages(['dispute' => ['Only a dispute under review can enter investigation.']]);
        }

        return $this->transition($dispute, DisputeStatus::UNDER_INVESTIGATION, $admin, $notes);
    }

    public function visibleTo(Dispute $dispute, User $user): void
    {
        $request = ServiceRequest::query()->findOrFail($dispute->service_request_id);
        $this->participantRole($request, $user);
    }

    public function forParticipant(User $user, string $role): mixed
    {
        if ($role === 'customer') {
            $requestIds = ServiceRequest::query()->where('customer_id', $user->getKey())->get()->pluck('_id')->map(fn($id) => (string) $id)->all();

            return Dispute::query()->get()->filter(fn(Dispute $dispute) => in_array((string) $dispute->service_request_id, $requestIds, true))->values();
        }

        $profile = $user->artisan()->firstOrFail();
        $requestIds = ServiceRequest::query()->where('selected_artisan_id', $profile->getKey())->get()->pluck('_id')->map(fn($id) => (string) $id)->all();

        return Dispute::query()->get()->filter(fn(Dispute $dispute) => in_array((string) $dispute->service_request_id, $requestIds, true))->values();
    }

    private function transition(Dispute $dispute, DisputeStatus $status, User $admin, string $notes): Dispute
    {
        $dispute->update([
            'status' => $status,
            'updates' => [...($dispute->updates ?? []), ['message' => $notes, 'submitted_at' => now(), 'submitted_by' => $admin->getKey(), 'submitted_by_role' => 'admin']],
            'status_history' => [...($dispute->status_history ?? []), $this->history($status, $admin, ['notes' => $notes])],
        ]);

        return $dispute->fresh();
    }

    private function participantRole(ServiceRequest $request, User $user): string
    {
        if ($request->customer_id === $user->getKey()) {
            return 'customer';
        }

        $profile = $user->artisan()->first();
        abort_unless($profile && $request->selected_artisan_id === $profile->getKey(), 404);

        return 'artisan';
    }

    private function activeDispute(ServiceRequest $request): ?Dispute
    {
        return Dispute::query()->get()->first(
            fn(Dispute $dispute) => $dispute->service_request_id === $request->getKey()
                && in_array($dispute->status, [
                    DisputeStatus::OPENED,
                    DisputeStatus::UNDER_REVIEW,
                    DisputeStatus::AWAITING_INFORMATION,
                    DisputeStatus::PENDING_EXECUTION,
                    DisputeStatus::UNDER_INVESTIGATION,
                    DisputeStatus::RESOLVED_WITH_MANUAL_REFUND_PENDING,
                ], true),
        );
    }

    private function recordPaymentDisputeHold(ServiceRequest $request, string $disputeId): void
    {
        $payment = $this->paymentFor($request);
        if (! $payment || $payment->status !== PaymentStatus::HELD) {
            return;
        }

        $payment->update(['events' => [...($payment->events ?? []), [
            'status' => PaymentStatus::HELD->value,
            'event' => 'dispute_opened',
            'occurred_at' => now(),
            'dispute_id' => $disputeId,
        ]]]);
    }

    private function paymentFor(ServiceRequest $request): ?Payment
    {
        return $request->payment_id
            ? Payment::query()->get()->first(fn(Payment $payment) => $payment->getKey() === $request->payment_id)
            : null;
    }

    /**
     * Normalises the incoming evidence array.
     *
     * Evidence entries can be either:
     *   - a string reference id (legacy / plain path)
     *   - a structured array returned by the evidence upload endpoint
     *     (id, path, name, mime_type, size)
     *
     * Both shapes are preserved in the stored dispute, so the frontend
     * can render either.
     */
    private function evidence(array $references, User $user): array
    {
        return collect($references)->map(function ($reference) use ($user) {
            $base = [
                'submitted_at' => now(),
                'submitted_by' => $user->getKey(),
            ];

            if (is_array($reference)) {
                return array_merge($reference, $base);
            }

            return array_merge(['reference' => (string) $reference], $base);
        })->all();
    }

    private function history(DisputeStatus $status, User $actor, array $context = []): array
    {
        return ['status' => $status->value, 'occurred_at' => now(), 'actor_id' => $actor->getKey(), ...$context];
    }
}
