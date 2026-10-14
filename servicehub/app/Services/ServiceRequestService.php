<?php

namespace App\Services;

use App\Enums\ServiceRequestStatus;
use App\Models\ServiceRequest;
use App\Models\User;
use App\Services\ServiceRequest\ServiceRequestLifecycleService;
use Illuminate\Validation\ValidationException;

class ServiceRequestService
{
    public function __construct(private readonly ServiceRequestLifecycleService $lifecycle) {}

    public function create(User $customer, array $data): ServiceRequest
    {
        return $this->lifecycle->submitNewRequest($customer, $data);
    }

    public function selectArtisan(ServiceRequest $serviceRequest, User $customer, string $artisanProfileId): ServiceRequest
    {
        return $this->lifecycle->selectArtisan($serviceRequest, $customer, $artisanProfileId);
    }

    public function ensureCustomerOwns(ServiceRequest $serviceRequest, User $customer): void
    {
        abort_unless($serviceRequest->customer_id === $customer->getKey(), 404);
    }

    public function updateRecoveryDetails(ServiceRequest $serviceRequest, User $customer, array $updates): ServiceRequest
    {
        return $this->lifecycle->updateRecoveryDetails($serviceRequest, $customer, $updates);
    }

    public function cancelByCustomer(ServiceRequest $serviceRequest, User $customer, string $reason): ServiceRequest
    {
        return $this->lifecycle->cancelByCustomer($serviceRequest, $customer, $reason);
    }

    public function scheduleInspection(ServiceRequest $serviceRequest, User $customer, array $data): ServiceRequest
    {
        $this->ensureCustomerOwns($serviceRequest, $customer);
        if (! in_array($serviceRequest->status, [ServiceRequestStatus::ARTISAN_SELECTED, ServiceRequestStatus::ARTISAN_APPROVED], true)) {
            throw ValidationException::withMessages(['service_request' => ['An inspection can only be scheduled after artisan approval.']]);
        }

        $inspection = [
            'scheduled_at' => $data['scheduled_at'],
            'call_out_fee' => $data['call_out_fee'] ?? 0,
            'notes' => $data['notes'] ?? null,
            'status' => 'scheduled',
        ];

        return $this->transition($serviceRequest, ServiceRequestStatus::INSPECTION_SCHEDULED, $customer, ['inspection' => $inspection]);
    }

    public function completeInspection(ServiceRequest $serviceRequest, User $artisan, array $data): ServiceRequest
    {
        $this->ensureSelectedArtisanOwns($serviceRequest, $artisan);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::INSPECTION_SCHEDULED, 'Only a scheduled inspection can be completed.');

        $inspection = [...($serviceRequest->inspection ?? []), 'status' => 'completed', 'findings' => $data['findings'], 'completed_at' => now()];

        return $this->transition($serviceRequest, ServiceRequestStatus::INSPECTION_COMPLETED, $artisan, ['inspection' => $inspection]);
    }

    public function submitQuotation(ServiceRequest $serviceRequest, User $artisan, array $data): ServiceRequest
    {
        $this->ensureSelectedArtisanOwns($serviceRequest, $artisan);

        if (! in_array($serviceRequest->status, [ServiceRequestStatus::ARTISAN_SELECTED, ServiceRequestStatus::ARTISAN_APPROVED, ServiceRequestStatus::INSPECTION_COMPLETED, ServiceRequestStatus::QUOTATION_PENDING], true)) {
            throw ValidationException::withMessages(['service_request' => ['A quotation cannot be submitted in the current request state.']]);
        }

        // Accept both spellings during the transition, then normalize
        // to a single canonical key so the customer-side parser has
        // exactly one shape to read.
        $labor = (float) ($data['labor_amount']
            ?? $data['labour_amount']
            ?? 0);

        unset($data['labour_amount']);
        $data['labor_amount'] = $labor;

        $quotation = [
            ...$data,
            'total' => $labor,
            'status' => 'received',
            'submitted_at' => now(),
            'submitted_by' => $artisan->getKey(),
        ];

        return $this->transition($serviceRequest, ServiceRequestStatus::QUOTATION_RECEIVED, $artisan, ['quotation' => $quotation]);
    }

    public function acceptQuotation(ServiceRequest $serviceRequest, User $customer): ServiceRequest
    {
        $this->ensureCustomerOwns($serviceRequest, $customer);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::QUOTATION_RECEIVED, 'Only a received quotation can be accepted.');

        $quotation = [...($serviceRequest->quotation ?? []), 'status' => 'accepted', 'accepted_at' => now()];

        return $this->transition($serviceRequest, ServiceRequestStatus::PAYMENT_PENDING, $customer, ['quotation' => $quotation]);
    }

    public function rejectQuotation(ServiceRequest $serviceRequest, User $customer, string $reason): ServiceRequest
    {
        $this->ensureCustomerOwns($serviceRequest, $customer);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::QUOTATION_RECEIVED, 'Only a received quotation can be rejected.');

        $quotation = [...($serviceRequest->quotation ?? []), 'status' => 'rejected', 'rejected_at' => now(), 'rejection_reason' => $reason];

        return $this->transition($serviceRequest, ServiceRequestStatus::QUOTATION_PENDING, $customer, ['quotation' => $quotation]);
    }

    public function proposeMaterials(ServiceRequest $serviceRequest, User $artisan, array $data): ServiceRequest
    {
        $this->ensureSelectedArtisanOwns($serviceRequest, $artisan);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::PAYMENT_PENDING, 'Materials can only be proposed after quotation acceptance.');

        $version = max(collect($serviceRequest->materials ?? [])->pluck('proposal_version')->map(fn($value) => (int) $value)->all() ?: [0]) + 1;
        $items = collect($data['materials'])->map(function (array $item) use ($version) {
            $item['estimated_cost'] = round($item['quantity'] * $item['unit_cost'], 2);
            $item['proposal_version'] = $version;
            $item['approval_status'] = 'proposed';

            return $item;
        })->all();

        $total = round(collect($items)->sum('estimated_cost'), 2);

        return $this->updateMaterials($serviceRequest, $artisan, $items, [
            'materials_proposal_version' => $version,
            'materials_estimated_total' => $total,
            'materials_approval_status' => 'proposed',
        ]);
    }

    public function approveMaterials(ServiceRequest $serviceRequest, User $customer, float $approvedTotal): ServiceRequest
    {
        $this->ensureCustomerOwns($serviceRequest, $customer);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::PAYMENT_PENDING, 'Materials can only be approved while payment is pending.');
        $materials = $serviceRequest->materials ?? [];

        if ($materials === [] || ($materials[0]['approval_status'] ?? null) !== 'proposed') {
            throw ValidationException::withMessages(['materials' => ['There is no pending materials proposal to approve.']]);
        }

        $estimatedTotal = round(collect($materials)->sum('estimated_cost'), 2);

        if (round($approvedTotal, 2) !== $estimatedTotal) {
            throw ValidationException::withMessages(['approved_total' => ['The approved total must equal the current materials estimate.']]);
        }

        $approvedMaterials = collect($materials)->map(fn(array $material) => [...$material, 'approval_status' => 'approved', 'approved_at' => now()])->all();

        return $this->updateMaterials($serviceRequest, $customer, $approvedMaterials, [
            'materials_approved_total' => $estimatedTotal,
            'materials_approval_status' => 'approved',
        ]);
    }

    public function startService(ServiceRequest $serviceRequest, User $artisan): ServiceRequest
    {
        $this->ensureSelectedArtisanOwns($serviceRequest, $artisan);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::BOOKED, 'A service can only start after its payment has been verified and booked.');

        return $this->transition($serviceRequest, ServiceRequestStatus::IN_PROGRESS, $artisan, [
            'completion' => [...($serviceRequest->completion ?? []), 'started_at' => now()],
        ]);
    }

    public function reportCompletion(ServiceRequest $serviceRequest, User $artisan, ?string $notes): ServiceRequest
    {
        $this->ensureSelectedArtisanOwns($serviceRequest, $artisan);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::IN_PROGRESS, 'Only an in-progress service can be reported as complete.');

        // The payout is auto-triggered when the customer confirms
        // completion. Without a payout phone, that release fails.
        // Block the artisan here so the failure surfaces early,
        // with clear guidance, instead of after a completed job.
        $profile = $artisan->artisan()->first();
        if (! $profile || ! filled($profile->payout_phone)) {
            throw ValidationException::withMessages([
                'payout_phone' => [
                    'Set your payout phone number in your profile before reporting completion. '
                        . 'This is where your earnings will be sent.',
                ],
            ]);
        }

        return $this->transition($serviceRequest, ServiceRequestStatus::AWAITING_CONFIRMATION, $artisan, [
            'completion' => [...($serviceRequest->completion ?? []), 'status' => 'awaiting_customer_confirmation', 'reported_at' => now(), 'reported_by' => $artisan->getKey(), 'notes' => $notes],
        ]);
    }

    public function confirmCompletion(ServiceRequest $serviceRequest, User $customer): ServiceRequest
    {
        $this->ensureCustomerOwns($serviceRequest, $customer);
        $this->ensureStatus($serviceRequest, ServiceRequestStatus::AWAITING_CONFIRMATION, 'Only a reported completion can be confirmed.');

        return $this->transition($serviceRequest, ServiceRequestStatus::COMPLETED, $customer, [
            'completion' => [...($serviceRequest->completion ?? []), 'status' => 'confirmed', 'confirmed_at' => now(), 'confirmed_by' => $customer->getKey()],
        ]);
    }

    public function markBookedFromVerifiedPayment(ServiceRequest $serviceRequest, string $paymentId): ServiceRequest
    {
        if ($serviceRequest->status !== ServiceRequestStatus::PAYMENT_PENDING) {
            return $serviceRequest;
        }

        $serviceRequest->update([
            'status' => ServiceRequestStatus::BOOKED,
            'payment_id' => $paymentId,
            'status_history' => [...($serviceRequest->status_history ?? []), [
                'status' => ServiceRequestStatus::BOOKED->value,
                'occurred_at' => now(),
                'actor_type' => 'system',
                'payment_id' => $paymentId,
            ]],
        ]);

        return $serviceRequest->fresh(['service', 'selectedArtisan.user']);
    }

    private function updateMaterials(ServiceRequest $serviceRequest, User $actor, array $materials, array $context): ServiceRequest
    {
        $serviceRequest->update([
            'materials' => $materials,
            'status_history' => [...($serviceRequest->status_history ?? []), $this->history($serviceRequest->status, $actor, [
                ...$context,
                'materials_snapshot' => $materials,
            ])],
        ]);

        return $serviceRequest->fresh(['service', 'selectedArtisan.user']);
    }

    public function ensureSelectedArtisanOwns(ServiceRequest $serviceRequest, User $artisan): void
    {
        $profile = $artisan->artisan()->first();
        abort_unless(
            $profile && (string) $serviceRequest->selected_artisan_id === (string) $profile->getKey(),
            404,
        );
    }

    private function transition(ServiceRequest $serviceRequest, ServiceRequestStatus $status, User $actor, array $updates = []): ServiceRequest
    {
        $serviceRequest->update([
            ...$updates,
            'status' => $status,
            'status_history' => [...($serviceRequest->status_history ?? []), $this->history($status, $actor)],
        ]);

        return $serviceRequest->fresh(['service', 'selectedArtisan.user']);
    }

    private function ensureStatus(ServiceRequest $serviceRequest, ServiceRequestStatus $expected, string $message): void
    {
        if ($serviceRequest->status !== $expected) {
            throw ValidationException::withMessages(['service_request' => [$message]]);
        }
    }

    private function history(ServiceRequestStatus $status, User $actor, array $context = []): array
    {
        return [
            'status' => $status->value,
            'occurred_at' => now(),
            'actor_id' => $actor->getKey(),
            ...$context,
        ];
    }
}
