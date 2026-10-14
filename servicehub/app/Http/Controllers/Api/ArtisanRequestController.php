<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ServiceRequest\CompleteInspectionRequest;
use App\Http\Requests\Artisan\DeclineRequestRequest;
use App\Http\Requests\ServiceRequest\ProposeMaterialsRequest;
use App\Http\Requests\ServiceRequest\ReportCompletionRequest;
use App\Http\Requests\ServiceRequest\StoreQuotationRequest;
use App\Jobs\AnalyzeQuotationJob;
use App\Models\ServiceRequest;
use App\Services\ServiceRequestMediaService;
use App\Services\ServiceRequestService;
use App\Services\ServiceRequest\ServiceRequestLifecycleService;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ArtisanRequestController extends Controller
{
    public function __construct(
        private readonly ServiceRequestService $serviceRequestService,
        private readonly ServiceRequestMediaService $media,
        private readonly ServiceRequestLifecycleService $lifecycle,
    ) {}

    /**
     * Lists all service requests assigned to the authenticated artisan.
     *
     * Optional `status` query parameter filters the results.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $profile = $user->artisan()->first();

        if (! $profile) {
            return response()->json([
                'service_requests' => [],
            ]);
        }

        $query = ServiceRequest::query()
            ->where('selected_artisan_id', (string) $profile->getKey())
            ->with(['service', 'customer']);

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        $requests = $query->latest()->get();

        return response()->json([
            'service_requests' => $requests->map(function (ServiceRequest $sr) {
                return [
                    'id' => (string) $sr->getKey(),
                    'status' => $sr->status?->value ?? (string) $sr->status,
                    'description' => $sr->description,
                    'location' => $sr->location,
                    'urgency' => $sr->urgency?->value ?? $sr->urgency,
                    'created_at' => $sr->created_at,
                    'pending_since' => $sr->pending_since,
                    'quotation' => $sr->quotation,
                    'service' => $sr->service ? [
                        'id' => (string) $sr->service->getKey(),
                        'name' => $sr->service->name,
                    ] : null,
                    'customer' => $sr->customer ? [
                        'id' => (string) $sr->customer->getKey(),
                        'first_name' => $sr->customer->first_name ?? '',
                        'name' => $sr->customer->name ?? '',
                    ] : null,
                ];
            })->values(),
        ]);
    }

    /**
     * Shows the full details of a single request assigned to the
     * authenticated artisan.
     */
    /**
     * Shows the full details of a single request assigned to the
     * authenticated artisan.
     */
    public function show(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $user = $request->user();
        $profile = $user->artisan()->first();

        if (! $profile) {
            abort(404, 'Artisan profile not found.');
        }

        // Only allow the assigned artisan to view this request.
        abort_unless(
            (string) $serviceRequest->selected_artisan_id === (string) $profile->getKey(),
            404,
        );

        return response()->json([
            'service_request' => $serviceRequest->load([
                'service',
                'selectedArtisan.user',
                'customer',
            ]),
        ]);
    }

    public function approve(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->lifecycle->artisanApproves($serviceRequest, $request->user())]);
    }

    public function decline(DeclineRequestRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->lifecycle->artisanDeclines(
            $serviceRequest,
            $request->user(),
            $request->validated('reason'),
        )]);
    }

    public function downloadImage(Request $request, ServiceRequest $serviceRequest, string $imageId)
    {
        $image = $this->media->imageForSelectedArtisan($serviceRequest, $request->user(), $imageId);

        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('local');

        return $disk->download($image['path'], $image['name'], ['Content-Type' => $image['mime_type']]);
    }

    public function completeInspection(CompleteInspectionRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->completeInspection(
            $serviceRequest,
            $request->user(),
            $request->validated(),
        )]);
    }

    public function submitQuotation(StoreQuotationRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest = $this->serviceRequestService->submitQuotation(
            $serviceRequest,
            $request->user(),
            $request->validated(),
        );
        AnalyzeQuotationJob::dispatch($serviceRequest->getKey());

        return response()->json(['service_request' => $serviceRequest]);
    }

    public function proposeMaterials(ProposeMaterialsRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->proposeMaterials(
            $serviceRequest,
            $request->user(),
            $request->validated(),
        )]);
    }

    public function start(ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->startService($serviceRequest, request()->user())]);
    }

    public function reportCompletion(ReportCompletionRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        return response()->json(['service_request' => $this->serviceRequestService->reportCompletion(
            $serviceRequest,
            $request->user(),
            $request->validated('notes'),
        )]);
    }
}
