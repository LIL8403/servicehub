<?php

namespace App\Services\ServiceRequest;

use App\Enums\ServiceRequestStatus;
use App\Models\Artisan;
use App\Models\PlatformSetting;
use App\Models\Service;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\Artisan\ArtisanMatchingService;
use App\Services\Ai\ArtisanRankingService;
use Illuminate\Validation\ValidationException;

class ServiceRequestLifecycleService
{
    public function __construct(
        private readonly ArtisanMatchingService $matching,
        private readonly ArtisanRankingService $ranking,
    ) {}

    public function submitNewRequest(User $customer, array $data): ServiceRequest
    {
        $service = Service::query()->where('_id', $data['service_id'])->where('is_active', true)->firstOrFail();
        $request = ServiceRequest::create([
            'customer_id' => $customer->getKey(),
            'service_id' => $service->getKey(),
            'description' => $data['description'],
            'location' => $data['location'],
            'formatted_address' => $data['formatted_address'] ?? null,
            'preferred_schedule' => $data['preferred_schedule'] ?? null,
            'ai_assist_enabled' => (bool) ($data['ai_assist_enabled'] ?? false),
            'status' => ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
            'matching_attempts' => 1,
            'selection_history' => [],
            'status_history' => [$this->history(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION, $customer, ['event' => 'submitted'])],
        ]);

        $eligibleArtisans = $this->matching->findEligibleArtisans($request);
        if ($eligibleArtisans->isEmpty()) {
            $reason = $this->matching->reasonForNoMatch($request);
            $request->update([
                'status' => ServiceRequestStatus::NO_ARTISAN_AVAILABLE,
                'no_artisan_reason' => $reason,
                'status_history' => [...($request->status_history ?? []), $this->history(ServiceRequestStatus::NO_ARTISAN_AVAILABLE, $customer, ['event' => 'matching_failed', 'reason' => $reason])],
            ]);
        } elseif ($request->ai_assist_enabled) {
            $rankings = $this->ranking->rankArtisans($request, $eligibleArtisans);
            $request->update([
                'recommendation' => $rankings === [] ? null : [
                    'artisan_rankings' => $rankings,
                    'generated_at' => now(),
                    'source' => 'ai',
                ],
                'status_history' => [...($request->status_history ?? []), $this->history(
                    $request->status,
                    $customer,
                    $rankings === []
                        ? ['event' => 'ai_ranking_empty']
                        : ['event' => 'ai_ranked', 'count' => count($rankings)],
                )],
            ]);
        }

        return $request->fresh(['service', 'selectedArtisan.user']);
    }

    public function selectArtisan(ServiceRequest $request, User $customer, string $artisanId): ServiceRequest
    {
        $this->ensureCustomerOwns($request, $customer);
        $this->guardAgainstReselection($request);
        if (! in_array($request->status, [ServiceRequestStatus::AWAITING_ARTISAN_SELECTION, ServiceRequestStatus::NO_ARTISAN_AVAILABLE], true)) {
            throw ValidationException::withMessages(['service_request' => ['Select an artisan only while the request is awaiting artisan selection.']]);
        }

        $artisan = Artisan::query()->findOrFail($artisanId);
        if (! $this->matching->findEligibleArtisans($request)->contains(fn (Artisan $candidate) => (string) $candidate->getKey() === (string) $artisan->getKey())) {
            throw ValidationException::withMessages(['artisan_profile_id' => ['The artisan is not eligible for this service request.']]);
        }

        $now = now();
        $request->update([
            'selected_artisan_id' => $artisan->getKey(),
            'status' => ServiceRequestStatus::PENDING_ARTISAN_RESPONSE,
            'pending_since' => $now,
            'no_artisan_reason' => null,
            'selection_history' => [...($request->selection_history ?? []), $this->selectionEvent('selected', $artisan, $now)],
            'status_history' => [...($request->status_history ?? []), $this->history(ServiceRequestStatus::PENDING_ARTISAN_RESPONSE, $customer, ['event' => 'artisan_selected', 'artisan_id' => $artisan->getKey()])],
        ]);

        return $request->fresh(['service', 'selectedArtisan.user']);
    }

    public function artisanApproves(ServiceRequest $request, User $artisan): ServiceRequest
    {
        $profile = $this->selectedArtisanProfile($request, $artisan);
        $this->ensurePendingResponse($request);

        $request->update([
            'status' => ServiceRequestStatus::ARTISAN_APPROVED,
            'pending_since' => null,
            'status_history' => [...($request->status_history ?? []), $this->history(ServiceRequestStatus::ARTISAN_APPROVED, $artisan, ['event' => 'artisan_approved', 'artisan_id' => $profile->getKey()])],
        ]);

        return $request->fresh(['service', 'selectedArtisan.user']);
    }

    public function artisanDeclines(ServiceRequest $request, User $artisan, ?string $reason = null): ServiceRequest
    {
        $profile = $this->selectedArtisanProfile($request, $artisan);
        $this->ensurePendingResponse($request);

        return $this->clearSelection($request, ServiceRequestStatus::AWAITING_ARTISAN_SELECTION, $artisan, 'declined', $profile, $reason);
    }

    public function customerChangesArtisan(ServiceRequest $request, User $customer, ?string $reason = null): ServiceRequest
    {
        $this->ensureCustomerOwns($request, $customer);
        $this->guardAgainstReselection($request);
        $this->ensurePendingResponse($request);
        $profile = Artisan::query()->findOrFail($request->selected_artisan_id);

        return $this->clearSelection($request, ServiceRequestStatus::AWAITING_ARTISAN_SELECTION, $customer, 'changed_by_customer', $profile, $reason);
    }

    public function timeoutPendingResponse(ServiceRequest $request): ServiceRequest
    {
        $this->ensurePendingResponse($request);
        $cutoff = now()->subHours($this->artisanResponseTimeoutHours());
        if ($request->pending_since === null || $request->pending_since->greaterThan($cutoff)) {
            throw ValidationException::withMessages(['service_request' => ['The artisan response timeout has not elapsed.']]);
        }
        $profile = Artisan::query()->findOrFail($request->selected_artisan_id);

        return $this->clearSelection($request, ServiceRequestStatus::AWAITING_ARTISAN_SELECTION, null, 'timeout', $profile);
    }

    public function retryMatching(ServiceRequest $request, User $customer): ServiceRequest
    {
        $this->ensureCustomerOwns($request, $customer);
        if ($request->status !== ServiceRequestStatus::NO_ARTISAN_AVAILABLE) {
            throw ValidationException::withMessages(['service_request' => ['Matching can only be retried when no artisan is currently available.']]);
        }

        $attempts = (int) ($request->matching_attempts ?? 0) + 1;
        if ($this->matching->countEligibleArtisans($request) === 0) {
            $reason = $this->matching->reasonForNoMatch($request);
            $request->update([
                'matching_attempts' => $attempts,
                'no_artisan_reason' => $reason,
                'status_history' => [...($request->status_history ?? []), $this->history(ServiceRequestStatus::NO_ARTISAN_AVAILABLE, $customer, ['event' => 'retry_failed', 'reason' => $reason])],
            ]);
        } else {
            $request->update([
                'matching_attempts' => $attempts,
                'status' => ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
                'no_artisan_reason' => null,
                'status_history' => [...($request->status_history ?? []), $this->history(ServiceRequestStatus::AWAITING_ARTISAN_SELECTION, $customer, ['event' => 'retry_succeeded'])],
            ]);
        }

        return $request->fresh(['service', 'selectedArtisan.user']);
    }

    /**
     * Updates request details only while no artisan has approved the work.
     * A location or preferred-schedule change always re-runs deterministic matching.
     */
    public function updateRecoveryDetails(ServiceRequest $request, User $customer, array $updates): ServiceRequest
    {
        $this->ensureCustomerOwns($request, $customer);

        if (! in_array($request->status, [
            ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
            ServiceRequestStatus::NO_ARTISAN_AVAILABLE,
        ], true)) {
            throw ValidationException::withMessages(['service_request' => ['Request details can only be changed before an artisan has been selected or after matching found no artisan.']]);
        }

        $attempts = (int) ($request->matching_attempts ?? 0) + 1;
        $request->fill([...$updates, 'matching_attempts' => $attempts]);
        $hasEligibleArtisan = $this->matching->countEligibleArtisans($request) > 0;
        $status = $hasEligibleArtisan
            ? ServiceRequestStatus::AWAITING_ARTISAN_SELECTION
            : ServiceRequestStatus::NO_ARTISAN_AVAILABLE;
        $reason = $hasEligibleArtisan ? null : $this->matching->reasonForNoMatch($request);

        $request->fill([
            'status' => $status,
            'no_artisan_reason' => $reason,
            'status_history' => [...($request->status_history ?? []), $this->history($status, $customer, [
                'event' => $hasEligibleArtisan ? 'request_updated_matching_available' : 'request_updated_no_match',
                'reason' => $reason,
            ])],
        ])->save();

        return $request->fresh(['service', 'selectedArtisan.user']);
    }

    /**
     * Customer self-service cancellation ends before quotation acceptance.
     * Once payment may be involved, cancellation must follow the payment/dispute process.
     */
    public function cancelByCustomer(ServiceRequest $request, User $customer, string $reason): ServiceRequest
    {
        $this->ensureCustomerOwns($request, $customer);

        if (! in_array($request->status, [
            ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
            ServiceRequestStatus::NO_ARTISAN_AVAILABLE,
            ServiceRequestStatus::PENDING_ARTISAN_RESPONSE,
            ServiceRequestStatus::ARTISAN_SELECTED,
            ServiceRequestStatus::ARTISAN_APPROVED,
            ServiceRequestStatus::INSPECTION_SCHEDULED,
            ServiceRequestStatus::INSPECTION_COMPLETED,
            ServiceRequestStatus::QUOTATION_PENDING,
            ServiceRequestStatus::QUOTATION_RECEIVED,
        ], true)) {
            throw ValidationException::withMessages(['service_request' => ['This request can no longer be cancelled directly. Use the payment support or dispute process instead.']]);
        }

        $request->update([
            'status' => ServiceRequestStatus::CANCELLED,
            'pending_since' => null,
            'cancellation' => [
                'status' => 'cancelled_by_customer',
                'reason' => $reason,
                'cancelled_at' => now(),
                'cancelled_by' => $customer->getKey(),
            ],
            'status_history' => [...($request->status_history ?? []), $this->history(ServiceRequestStatus::CANCELLED, $customer, [
                'event' => 'cancelled_by_customer',
                'reason' => $reason,
            ])],
        ]);

        return $request->fresh(['service', 'selectedArtisan.user']);
    }

    public function guardAgainstReselection(ServiceRequest $request): void
    {
        if (in_array($request->status, [
            ServiceRequestStatus::QUOTATION_ACCEPTED,
            ServiceRequestStatus::PAYMENT_PENDING,
            ServiceRequestStatus::BOOKED,
            ServiceRequestStatus::IN_PROGRESS,
            ServiceRequestStatus::AWAITING_CONFIRMATION,
            ServiceRequestStatus::COMPLETED,
            ServiceRequestStatus::CANCELLED,
            ServiceRequestStatus::DISPUTED,
        ], true)) {
            throw ValidationException::withMessages(['service_request' => ['Artisan reassignment now requires the controlled cancellation or dispute process.']]);
        }
    }

    private function clearSelection(ServiceRequest $request, ServiceRequestStatus $status, ?User $actor, string $event, Artisan $profile, ?string $reason = null): ServiceRequest
    {
        $now = now();
        $request->update([
            'selected_artisan_id' => null,
            'pending_since' => null,
            'status' => $status,
            'selection_history' => [...($request->selection_history ?? []), $this->selectionEvent($event, $profile, $now, $reason)],
            'status_history' => [...($request->status_history ?? []), $this->history($status, $actor, ['event' => "artisan_{$event}", 'artisan_id' => $profile->getKey(), 'reason' => $reason])],
        ]);

        return $request->fresh(['service', 'selectedArtisan.user']);
    }

    private function selectedArtisanProfile(ServiceRequest $request, User $artisan): Artisan
    {
        $profile = $artisan->artisan()->first();
        abort_unless($profile && (string) $request->selected_artisan_id === (string) $profile->getKey(), 404);

        return $profile;
    }

    private function ensurePendingResponse(ServiceRequest $request): void
    {
        if ($request->status !== ServiceRequestStatus::PENDING_ARTISAN_RESPONSE) {
            throw ValidationException::withMessages(['service_request' => ['The request is not awaiting an artisan response.']]);
        }
    }

    private function artisanResponseTimeoutHours(): int
    {
        return max(1, (int) (PlatformSetting::query()
            ->where('key', 'artisan_response_timeout_hours')
            ->value('value') ?? 24));
    }

    private function ensureCustomerOwns(ServiceRequest $request, User $customer): void
    {
        abort_unless((string) $request->customer_id === (string) $customer->getKey(), 404);
    }

    private function selectionEvent(string $event, Artisan $artisan, mixed $occurredAt, ?string $reason = null): array
    {
        return ['event' => $event, 'artisan_id' => $artisan->getKey(), 'artisan_name' => $artisan->user?->name, 'occurred_at' => $occurredAt, 'reason' => $reason];
    }

    private function history(ServiceRequestStatus $status, ?User $actor, array $context = []): array
    {
        return ['status' => $status->value, 'occurred_at' => now(), 'actor_id' => $actor?->getKey(), ...$context];
    }
}
