<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Dispute\AddDisputeEvidenceRequest;
use App\Http\Requests\Dispute\OpenDisputeRequest;
use App\Models\Dispute;
use App\Models\ServiceRequest;
use App\Services\DisputeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DisputeController extends Controller
{
    public function __construct(private readonly DisputeService $disputes) {}

    public function customerIndex(Request $request): JsonResponse
    {
        return response()->json([
            'disputes' => $this->disputes->forParticipant($request->user(), 'customer'),
        ]);
    }

    public function artisanIndex(Request $request): JsonResponse
    {
        return response()->json([
            'disputes' => $this->disputes->forParticipant($request->user(), 'artisan'),
        ]);
    }

    public function open(OpenDisputeRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        // Evidence is uploaded separately via DisputeEvidenceController,
        // which returns structured references. We pass them through as-is;
        // DisputeService stores them with submission metadata attached.
        return response()->json([
            'dispute' => $this->disputes->open(
                $serviceRequest,
                $request->user(),
                $request->validated(),
            ),
        ], 201);
    }

    public function addEvidence(AddDisputeEvidenceRequest $request, Dispute $dispute): JsonResponse
    {
        return response()->json([
            'dispute' => $this->disputes->addEvidence(
                $dispute,
                $request->user(),
                $request->validated(),
            ),
        ]);
    }
}