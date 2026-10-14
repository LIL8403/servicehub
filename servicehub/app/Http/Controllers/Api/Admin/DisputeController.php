<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\DisputeStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\CancelDisputeResolutionRequest;
use App\Http\Requests\Admin\ResolveDisputeRequest;
use App\Http\Requests\Admin\UpdateDisputeRequest;
use App\Models\Dispute;
use App\Models\Payment;
use App\Services\DisputeResolutionService;
use App\Services\DisputeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DisputeController extends Controller
{
    public function __construct(
        private readonly DisputeService $disputes,
        private readonly DisputeResolutionService $resolutions,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'status' => ['nullable', 'string', 'in:' . collect(DisputeStatus::cases())->map(fn(DisputeStatus $status) => $status->value)->implode(',')],
        ]);
        $disputes = Dispute::query()->latest();
        if (isset($filters['status'])) {
            $disputes->where('status', $filters['status']);
        }

        $rows = $disputes->get()->map(function (Dispute $d) {
            $reporter = \App\Models\User::query()->find($d->reporter_id);
            $serviceRequest = \App\Models\ServiceRequest::query()->find($d->service_request_id);
            $service = $serviceRequest
                ? \App\Models\Service::query()->find($serviceRequest->service_id)
                : null;

            return [
                'id' => (string) $d->getKey(),
                'status' => $d->status->value,
                'reason' => $d->reason,
                'description' => $d->description,
                'urgency' => $d->urgency,
                'reporter_id' => $d->reporter_id,
                'reporter_role' => $d->reporter_role,
                'reporter_name' => $reporter?->name,
                'service_request_id' => $d->service_request_id,
                'service_name' => $service?->name,
                'created_at' => $d->created_at,
                'updated_at' => $d->updated_at,
            ];
        });

        return response()->json(['disputes' => $rows]);
    }

    public function startReview(UpdateDisputeRequest $request, Dispute $dispute): JsonResponse
    {
        return response()->json(['dispute' => $this->disputes->startReview($dispute, $request->user(), $request->validated('notes'))]);
    }

    public function awaitInformation(UpdateDisputeRequest $request, Dispute $dispute): JsonResponse
    {
        return response()->json(['dispute' => $this->disputes->awaitInformation($dispute, $request->user(), $request->validated('notes'))]);
    }

    public function show(Dispute $dispute): JsonResponse
    {
        $reporter = \App\Models\User::query()->find($dispute->reporter_id);
        $serviceRequest = \App\Models\ServiceRequest::query()->find($dispute->service_request_id);
        $service = $serviceRequest
            ? \App\Models\Service::query()->find($serviceRequest->service_id)
            : null;
        $artisan = $serviceRequest?->selectedArtisan()->first();
        $artisanUser = $artisan ? \App\Models\User::query()->find($artisan->user_id) : null;
        $customerUser = $serviceRequest
            ? \App\Models\User::query()->find($serviceRequest->customer_id)
            : null;

        $isSimulated = (bool) (data_get($dispute->resolution, 'is_simulated') ?? data_get($dispute->pending_resolution, 'is_simulated') ?? false);

        return response()->json([
            'dispute' => [
                'id' => (string) $dispute->getKey(),
                'service_request_id' => $dispute->service_request_id,
                'payment_id' => $dispute->payment_id,
                'reporter_id' => $dispute->reporter_id,
                'reporter_role' => $dispute->reporter_role,
                'reporter_name' => $reporter?->name,
                'reason' => $dispute->reason,
                'description' => $dispute->description,
                'urgency' => $dispute->urgency,
                'evidence' => $dispute->evidence ?? [],
                'updates' => $dispute->updates ?? [],
                'status' => $dispute->status->value,
                'prior_request_status' => $dispute->prior_request_status,
                'status_history' => $dispute->status_history ?? [],
                'resolution' => $dispute->resolution,
                'pending_resolution' => $dispute->pending_resolution,
                'resolution_reference' => $dispute->resolution_reference,
                'created_at' => $dispute->created_at,
                'updated_at' => $dispute->updated_at,
                'service_name' => $service?->name,
                'customer_name' => $customerUser?->name,
                'artisan_name' => $artisanUser?->name,
            ],
            'payment' => Payment::query()->find($dispute->payment_id),
            'simulation_notice' => $isSimulated
                ? 'SIMULATED — no real funds moved.'
                : null,
        ]);
    }

    public function resolve(ResolveDisputeRequest $request, Dispute $dispute): JsonResponse
    {
        return response()->json(['dispute' => $this->resolutions->initiate($dispute, $request->user(), $request->validated())]);
    }

    public function confirmResolution(Request $request, Dispute $dispute): JsonResponse
    {
        return response()->json(['dispute' => $this->resolutions->confirm($dispute, $request->user())]);
    }

    public function cancelResolution(CancelDisputeResolutionRequest $request, Dispute $dispute): JsonResponse
    {
        return response()->json(['dispute' => $this->resolutions->cancel($dispute, $request->user(), $request->validated('reason'))]);
    }

    public function investigate(UpdateDisputeRequest $request, Dispute $dispute): JsonResponse
    {
        return response()->json(['dispute' => $this->disputes->investigate($dispute, $request->user(), $request->validated('notes'))]);
    }

    public function reconcile(UpdateDisputeRequest $request, Dispute $dispute): JsonResponse
    {
        return response()->json(['dispute' => $this->resolutions->reconcile($dispute, $request->user(), $request->validated('notes'))]);
    }

    public function downloadEvidence(Request $request, Dispute $dispute, string $evidenceId)
    {
        $evidence = collect($dispute->evidence ?? [])
            ->firstWhere('id', $evidenceId);

        if (! is_array($evidence)) {
            abort(404, 'Evidence not found.');
        }

        $path = $evidence['path'] ?? null;

        if (! is_string($path) || $path === '' || ! \Illuminate\Support\Facades\Storage::disk('local')->exists($path)) {
            abort(404);
        }

        return response()->streamDownload(function () use ($path): void {
            $stream = \Illuminate\Support\Facades\Storage::disk('local')->readStream($path);
            if ($stream !== false) {
                fpassthru($stream);
                fclose($stream);
            }
        }, $evidence['name'] ?? basename($path));
    }
}
