<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ServiceRequest\ApproveMaterialsRequest;
use App\Http\Requests\ServiceRequest\CancelServiceRequestRequest;
use App\Http\Requests\ServiceRequest\ChangeArtisanRequest;
use App\Http\Requests\ServiceRequest\RejectQuotationRequest;
use App\Http\Requests\ServiceRequest\ScheduleInspectionRequest;
use App\Http\Requests\ServiceRequest\SelectArtisanRequest;
use App\Http\Requests\ServiceRequest\StoreServiceRequestRequest;
use App\Http\Requests\ServiceRequest\UpdateServiceRequestRequest;
use App\Models\ServiceRequest;
use App\Services\Location\GeocodingService;
use App\Services\PaymentService;
use App\Services\ServiceRequestMediaService;
use App\Services\ServiceRequestService;
use App\Services\Artisan\ArtisanMatchingService;
use App\Services\ServiceRequest\ServiceRequestLifecycleService;
use App\Services\ServiceRequest\ServiceRequestTrackingService;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class ServiceRequestController extends Controller
{
    public function __construct(
        private readonly ServiceRequestService $serviceRequestService,
        private readonly PaymentService $paymentService,
        private readonly GeocodingService $geocodingService,
        private readonly ServiceRequestMediaService $media,
        private readonly ServiceRequestLifecycleService $lifecycle,
        private readonly ArtisanMatchingService $matching,
        private readonly ServiceRequestTrackingService $tracking,
    ) {}

    public function index(Request $request): JsonResponse
    {
        return response()->json([
            'service_requests' => ServiceRequest::query()
                ->where('customer_id', $request->user()->getKey())
                ->with(['service', 'selectedArtisan.user'])
                ->latest()
                ->get(),
        ]);
    }

    public function store(StoreServiceRequestRequest $request): JsonResponse
    {
        $data = $request->validated();

        if (! isset($data['location'])) {
            $location = $this->geocodingService->geocode($data['address']);

            if ($location === null) {
                throw ValidationException::withMessages([
                    'address' => ['We could not locate that address. Enter a valid map location or provide a manual pin.'],
                ]);
            }

            $data['location'] = [
                ...$this->geocodingService->toGeoJson($location['latitude'], $location['longitude']),
                'label' => $location['formatted_address'],
            ];
            $data['formatted_address'] = $location['formatted_address'];
        }

        $serviceRequest = $this->serviceRequestService->create($request->user(), $data);

        try {
            $serviceRequest = $this->media->attachImages($serviceRequest, $data['images'] ?? []);
        } catch (\Throwable $exception) {
            $serviceRequest->delete();

            throw $exception;
        }

        return response()->json(['service_request' => $serviceRequest->load('service')], 201);
    }

    public function show(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->serviceRequestService->ensureCustomerOwns($serviceRequest, $request->user());

        return response()->json(['service_request' => $serviceRequest->load(['service', 'selectedArtisan.user'])]);
    }

    public function tracking(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->serviceRequestService->ensureCustomerOwns($serviceRequest, $request->user());

        return response()->json($this->tracking->customerPayload($serviceRequest));
    }

    public function update(UpdateServiceRequestRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $data = $request->validated();

        if (array_key_exists('address', $data)) {
            $location = $this->geocodingService->geocode($data['address']);

            if ($location === null) {
                throw ValidationException::withMessages([
                    'address' => ['We could not locate that address. Enter a valid map location or provide a manual pin.'],
                ]);
            }

            $data['location'] = [
                ...$this->geocodingService->toGeoJson($location['latitude'], $location['longitude']),
                'label' => $location['formatted_address'],
            ];
            $data['formatted_address'] = $location['formatted_address'];
            unset($data['address']);
        } elseif (array_key_exists('location', $data)) {
            $data['formatted_address'] = $data['location']['label'];
        }

        return response()->json(['service_request' => $this->serviceRequestService->updateRecoveryDetails(
            $serviceRequest,
            $request->user(),
            $data,
        )]);
    }

    public function cancel(CancelServiceRequestRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->cancelByCustomer(
            $serviceRequest,
            $request->user(),
            $request->validated('reason'),
        )]);
    }

    public function downloadImage(Request $request, ServiceRequest $serviceRequest, string $imageId)
    {
        $image = $this->media->imageForCustomer($serviceRequest, $request->user(), $imageId);

        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('local');

        return $disk->download($image['path'], $image['name'], ['Content-Type' => $image['mime_type']]);
    }

    public function selectArtisan(SelectArtisanRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json([
            'service_request' => $this->serviceRequestService->selectArtisan(
                $serviceRequest,
                $request->user(),
                $request->validated('artisan_profile_id'),
            ),
        ]);
    }

    public function changeArtisan(ChangeArtisanRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->lifecycle->customerChangesArtisan(
            $serviceRequest,
            $request->user(),
            $request->validated('reason'),
        )]);
    }

    public function retryMatching(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->lifecycle->retryMatching($serviceRequest, $request->user())]);
    }

    public function eligibleArtisans(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->serviceRequestService->ensureCustomerOwns($serviceRequest, $request->user());

        $artisans = $this->matching->findEligibleArtisans($serviceRequest);
        $aiRecommendations = data_get($serviceRequest->recommendation, 'artisan_rankings', []);
        $aiRecommendations = is_array($aiRecommendations) ? $aiRecommendations : [];

        return response()->json([
            'artisans' => $artisans->map(function ($artisan) use ($serviceRequest) {
                $user = $artisan->user;

                return [
                    'id' => (string) $artisan->getKey(),
                    'user' => [
                        'id' => (string) ($user?->getKey() ?? ''),
                        'name' => $user?->name ?? '',
                        'first_name' => $user?->first_name ?? '',
                        'last_name' => $user?->last_name ?? '',
                        'has_photo' => ! empty($user?->profile_photo),
                    ],
                    'professional_title' => $artisan->professional_title,
                    'professional_description' => $artisan->professional_description ?? $artisan->bio,
                    'bio' => $artisan->bio,
                    'experience_years' => $artisan->experience_years,
                    'service_areas' => $artisan->service_areas ?? [],
                    'location' => $artisan->location ?? $artisan->service_location,
                    'availability' => $artisan->availability ?? [],
                    'rating_average' => (float) ($artisan->rating_average ?? 0),
                    'review_count' => (int) ($artisan->review_count ?? 0),
                    'completed_jobs' => (int) ($artisan->completed_jobs ?? 0),
                    'response_rate' => (float) ($artisan->response_rate ?? 0),
                    'cancellation_rate' => (float) ($artisan->cancellation_rate ?? 0),
                    'languages' => $artisan->languages ?? [],
                    'certifications' => $artisan->certifications ?? [],
                    'distance_km' => $this->calculateDistanceKm($artisan, $serviceRequest),
                ];
            })->values(),
            'ai_recommendations' => $aiRecommendations,
            'request' => [
                'id' => (string) $serviceRequest->getKey(),
                'service_id' => (string) $serviceRequest->service_id,
                'status' => $serviceRequest->status?->value ?? (string) $serviceRequest->status,
                'location' => $serviceRequest->location,
                'preferred_schedule' => $serviceRequest->preferred_schedule,
                'ai_assist_enabled' => (bool) $serviceRequest->ai_assist_enabled,
                'ai_recommendations_available' => $aiRecommendations !== [],
                'no_artisan_reason' => $serviceRequest->no_artisan_reason,
            ],
        ]);
    }

    /**
     * Compute the straight-line distance between the artisan's base and
     * the request's location, in kilometres. Returns null when either
     * coordinate set is missing.
     */
    private function calculateDistanceKm($artisan, ServiceRequest $serviceRequest): ?float
    {
        $artisanCoords = data_get($artisan->location, 'coordinates')
            ?? data_get($artisan->service_location, 'coordinates');
        $requestCoords = data_get($serviceRequest->location, 'coordinates');

        if (
            ! is_array($artisanCoords) || ! is_array($requestCoords)
            || count($artisanCoords) !== 2 || count($requestCoords) !== 2
        ) {
            return null;
        }

        $earthRadiusKm = 6371.0;
        $deltaLat = deg2rad((float) $requestCoords[1] - (float) $artisanCoords[1]);
        $deltaLng = deg2rad((float) $requestCoords[0] - (float) $artisanCoords[0]);
        $a = sin($deltaLat / 2) ** 2
            + cos(deg2rad((float) $artisanCoords[1]))
            * cos(deg2rad((float) $requestCoords[1]))
            * sin($deltaLng / 2) ** 2;

        return round($earthRadiusKm * 2 * atan2(sqrt($a), sqrt(1 - $a)), 2);
    }

    public function scheduleInspection(ScheduleInspectionRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->scheduleInspection(
            $serviceRequest,
            $request->user(),
            $request->validated(),
        )]);
    }

    public function acceptQuotation(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->acceptQuotation($serviceRequest, $request->user())]);
    }

    public function rejectQuotation(RejectQuotationRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->rejectQuotation(
            $serviceRequest,
            $request->user(),
            $request->validated('reason'),
        )]);
    }

    public function approveMaterials(ApproveMaterialsRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->approveMaterials(
            $serviceRequest,
            $request->user(),
            (float) $request->validated('approved_total'),
        )]);
    }

    public function confirmCompletion(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest = $this->serviceRequestService->confirmCompletion($serviceRequest, $request->user());
        $payout = $this->paymentService->releaseForCompletedRequest($serviceRequest, $request->user());

        return response()->json(['service_request' => $serviceRequest, 'payout' => $payout]);
    }

    public function retryPayout(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->serviceRequestService->ensureCustomerOwns($serviceRequest, $request->user());
        if ($serviceRequest->status->value !== 'completed') {
            abort(422, 'A payout can only be retried for a completed service request.');
        }

        return response()->json(['payout' => $this->paymentService->releaseForCompletedRequest($serviceRequest, $request->user())]);
    }
}
