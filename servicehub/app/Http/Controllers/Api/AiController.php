<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceRequest;
use App\Services\Ai\AiOrchestrationService;
use App\Services\ServiceRequestService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AiController extends Controller
{
    public function __construct(private readonly AiOrchestrationService $ai, private readonly ServiceRequestService $requests) {}

    public function recommend(Request $request): JsonResponse
    {
        $data = $request->validate(['service_request_id' => ['required', 'string']]);
        $serviceRequest = ServiceRequest::query()->findOrFail($data['service_request_id']);
        $this->requests->ensureCustomerOwns($serviceRequest, $request->user());
        $recommendation = $this->ai->recommendArtisans($serviceRequest);
        $serviceRequest->update(['recommendation' => [...($serviceRequest->recommendation ?? []), 'artisans' => $recommendation]]);

        return response()->json(['recommendation' => $recommendation]);
    }

    public function understand(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->requests->ensureCustomerOwns($serviceRequest, $request->user());
        $understanding = $this->ai->understandRequest($serviceRequest);
        $serviceRequest->update(['recommendation' => [...($serviceRequest->recommendation ?? []), 'request_understanding' => $understanding]]);

        return response()->json(['request_understanding' => $understanding]);
    }

    public function understandDraft(Request $request): JsonResponse
    {
        $data = $request->validate([
            'description' => ['required', 'string', 'max:1000'],
            'service_id' => ['nullable', 'string'],
            'preferred_schedule' => ['nullable', 'array'],
        ]);

        $understanding = $this->ai->understandDraft(
            description: $data['description'],
            serviceId: $data['service_id'] ?? null,
            preferredSchedule: $data['preferred_schedule'] ?? null,
        );

        return response()->json(['request_understanding' => $understanding]);
    }

    public function analyzeQuotation(Request $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $this->requests->ensureCustomerOwns($serviceRequest, $request->user());

        $analysis = $this->ai->analyzeQuotationForCustomer($serviceRequest);

        // Persist so the artisan's view of the request stays in sync
        // with what the customer just saw. Only overwrite on a
        // successful analysis — a transient provider failure should
        // not erase the last known good analysis.
        if (($analysis['available'] ?? false) === true) {
            $this->ai->persistAnalysis($serviceRequest, $analysis);
        }

        return response()->json(['quotation_analysis' => $analysis]);
    }
}
