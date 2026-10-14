<?php

namespace App\Services\ServiceRequest;

use App\Enums\ServiceRequestStatus;
use App\Models\PlatformSetting;
use App\Models\ServiceRequest;
use Carbon\CarbonInterface;

class ServiceRequestTrackingService
{
    public function customerPayload(ServiceRequest $request): array
    {
        $request->loadMissing(['service', 'selectedArtisan.user']);

        $status = $request->status instanceof ServiceRequestStatus
            ? $request->status
            : ServiceRequestStatus::tryFrom((string) $request->status);
        $pendingResponse = $this->pendingResponse($request, $status);

        return [
            'service_request' => [
                'id' => (string) $request->getKey(),
                'status' => $status?->value,
                'description' => $request->description,
                'urgency' => $request->urgency?->value ?? $request->urgency,
                'location' => $request->location,
                'preferred_schedule' => $request->preferred_schedule,
                'no_artisan_reason' => $request->no_artisan_reason,
                'ai_assist_enabled' => (bool) $request->ai_assist_enabled,
                'created_at' => $request->created_at,
                'updated_at' => $request->updated_at,
                'service' => $request->service ? [
                    'id' => (string) $request->service->getKey(),
                    'name' => $request->service->name,
                ] : null,
                'inspection' => $request->inspection,
                'quotation' => $request->quotation,
                'materials' => $request->materials ?? [],
                'completion' => $request->completion,
                'cancellation' => $request->cancellation,
            ],
            'selected_artisan' => $this->artisan($request),
            'pending_response' => $pendingResponse,
            'next_action' => $this->nextAction($status, $request),
            'permissions' => [
                'can_select_artisan' => $status === ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
                'can_change_artisan' => $status === ServiceRequestStatus::PENDING_ARTISAN_RESPONSE,
                'can_retry_matching' => $status === ServiceRequestStatus::NO_ARTISAN_AVAILABLE,
                'can_edit_request' => $this->canEdit($status),
                'can_cancel_request' => $this->canCancel($status),
                'can_schedule_inspection' => in_array($status, [ServiceRequestStatus::ARTISAN_SELECTED, ServiceRequestStatus::ARTISAN_APPROVED], true),
                'can_accept_quotation' => $status === ServiceRequestStatus::QUOTATION_RECEIVED,
                'can_confirm_completion' => $status === ServiceRequestStatus::AWAITING_CONFIRMATION,
            ],
            'timeline' => collect($request->status_history ?? [])->map(function (array $entry) use ($status): array {
                $entryStatus = $entry['status'] ?? null;

                return [
                    'status' => $entryStatus,
                    'label' => $this->statusLabel($entryStatus),
                    'event' => $entry['event'] ?? null,
                    'reason' => $entry['reason'] ?? null,
                    'occurred_at' => $entry['occurred_at'] ?? null,
                    'is_current' => $entryStatus === $status?->value,
                ];
            })->values()->all(),
        ];
    }

    private function artisan(ServiceRequest $request): ?array
    {
        $artisan = $request->selectedArtisan;
        if ($artisan === null) {
            return null;
        }

        $user = $artisan->user;

        return [
            'id' => (string) $artisan->getKey(),
            'user_id' => (string) ($user?->getKey() ?? ''),
            'name' => $user?->name,
            'first_name' => $user?->first_name,
            'last_name' => $user?->last_name,
            'has_photo' => ! empty($user?->profile_photo),
            'professional_title' => $artisan->professional_title,
            'experience_years' => $artisan->experience_years,
            'rating_average' => (float) ($artisan->rating_average ?? 0),
            'review_count' => (int) ($artisan->review_count ?? 0),
            'response_rate' => (float) ($artisan->response_rate ?? 0),
        ];
    }

    private function pendingResponse(ServiceRequest $request, ?ServiceRequestStatus $status): ?array
    {
        if ($status !== ServiceRequestStatus::PENDING_ARTISAN_RESPONSE || ! $request->pending_since instanceof CarbonInterface) {
            return null;
        }

        $expiresAt = $request->pending_since->copy()->addHours($this->artisanResponseTimeoutHours());

        return [
            'pending_since' => $request->pending_since,
            'expires_at' => $expiresAt,
            'is_expired' => now()->greaterThanOrEqualTo($expiresAt),
        ];
    }

    private function nextAction(?ServiceRequestStatus $status, ServiceRequest $request): ?array
    {
        return match ($status) {
            ServiceRequestStatus::AWAITING_ARTISAN_SELECTION => ['key' => 'select_artisan', 'label' => 'View verified artisans'],
            ServiceRequestStatus::NO_ARTISAN_AVAILABLE => ['key' => 'retry_matching', 'label' => 'Try matching again'],
            ServiceRequestStatus::PENDING_ARTISAN_RESPONSE => ['key' => 'change_artisan', 'label' => 'Change artisan'],
            ServiceRequestStatus::ARTISAN_SELECTED,
            ServiceRequestStatus::ARTISAN_APPROVED => ['key' => 'message_artisan', 'label' => 'Message artisan'],
            ServiceRequestStatus::QUOTATION_RECEIVED => ['key' => 'review_quotation', 'label' => 'Review and pay'],
            ServiceRequestStatus::PAYMENT_PENDING => ['key' => 'complete_payment', 'label' => 'Complete payment'],
            ServiceRequestStatus::BOOKED,
            ServiceRequestStatus::IN_PROGRESS => ['key' => 'message_artisan', 'label' => 'Message artisan'],
            ServiceRequestStatus::AWAITING_CONFIRMATION => ['key' => 'confirm_completion', 'label' => 'Confirm completion'],
            default => null,
        };
    }

    private function canEdit(?ServiceRequestStatus $status): bool
    {
        return in_array($status, [
            ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
            ServiceRequestStatus::NO_ARTISAN_AVAILABLE,
        ], true);
    }

    private function canCancel(?ServiceRequestStatus $status): bool
    {
        return in_array($status, [
            ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
            ServiceRequestStatus::NO_ARTISAN_AVAILABLE,
            ServiceRequestStatus::PENDING_ARTISAN_RESPONSE,
            ServiceRequestStatus::ARTISAN_SELECTED,
            ServiceRequestStatus::ARTISAN_APPROVED,
            ServiceRequestStatus::INSPECTION_SCHEDULED,
            ServiceRequestStatus::INSPECTION_COMPLETED,
            ServiceRequestStatus::QUOTATION_PENDING,
            ServiceRequestStatus::QUOTATION_RECEIVED,
        ], true);
    }

    private function artisanResponseTimeoutHours(): int
    {
        return max(1, (int) (PlatformSetting::query()
            ->where('key', 'artisan_response_timeout_hours')
            ->value('value') ?? 24));
    }

    private function statusLabel(?string $status): string
    {
        return match ($status) {
            ServiceRequestStatus::AWAITING_ARTISAN_SELECTION->value => 'Choose an artisan',
            ServiceRequestStatus::NO_ARTISAN_AVAILABLE->value => 'No artisan currently available',
            ServiceRequestStatus::PENDING_ARTISAN_RESPONSE->value => 'Awaiting artisan response',
            ServiceRequestStatus::ARTISAN_APPROVED->value => 'Artisan approved',
            ServiceRequestStatus::INSPECTION_SCHEDULED->value => 'Inspection scheduled',
            ServiceRequestStatus::INSPECTION_COMPLETED->value => 'Inspection completed',
            ServiceRequestStatus::QUOTATION_PENDING->value => 'Awaiting quotation',
            ServiceRequestStatus::QUOTATION_RECEIVED->value => 'Quotation received',
            ServiceRequestStatus::PAYMENT_PENDING->value => 'Payment pending',
            ServiceRequestStatus::BOOKED->value => 'Booked',
            ServiceRequestStatus::IN_PROGRESS->value => 'Work in progress',
            ServiceRequestStatus::AWAITING_CONFIRMATION->value => 'Awaiting your confirmation',
            ServiceRequestStatus::COMPLETED->value => 'Completed',
            ServiceRequestStatus::CANCELLED->value => 'Cancelled',
            ServiceRequestStatus::DISPUTED->value => 'Disputed',
            default => 'Request updated',
        };
    }
}
