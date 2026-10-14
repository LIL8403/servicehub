<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\ServiceRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerPaymentController extends Controller
{
    /**
     * Lists every payment made by the authenticated customer, newest
     * first. Each entry is enriched with the service request's short
     * reference and the artisan's name so the client doesn't have to
     * fetch them separately.
     */
    public function index(Request $request): JsonResponse
    {
        $customerId = (string) $request->user()->getKey();

        $payments = Payment::query()
            ->where('customer_id', $customerId)
            ->orderBy('created_at', 'desc')
            ->limit((int) $request->query('limit', 50))
            ->get();

        // Preload the requests that these payments reference, so we
        // can attach the service name, reference, and artisan name.
        $requestIds = $payments
            ->pluck('service_request_id')
            ->filter()
            ->map(fn ($id) => (string) $id)
            ->unique()
            ->all();

        $requests = ServiceRequest::query()
            ->whereIn('_id', $requestIds)
            ->with(['service', 'selectedArtisan.user'])
            ->get()
            ->keyBy(fn (ServiceRequest $sr) => (string) $sr->getKey());

        return response()->json([
            'payments' => $payments->map(function (Payment $payment) use ($requests) {
                $sr = $requests->get((string) $payment->service_request_id);

                return [
                    'id' => (string) $payment->getKey(),
                    'service_request_id' => (string) $payment->service_request_id,
                    'amount' => (float) $payment->amount,
                    'currency' => $payment->currency,
                    'status' => $payment->status?->value ?? (string) $payment->status,
                    'provider_channel' => $payment->provider_channel,
                    'created_at' => $payment->created_at,
                    'updated_at' => $payment->updated_at,
                    'service' => $sr?->service ? [
                        'id' => (string) $sr->service->getKey(),
                        'name' => $sr->service->name,
                    ] : null,
                    'artisan' => $sr?->selectedArtisan?->user ? [
                        'id' => (string) $sr->selectedArtisan->user->getKey(),
                        'name' => $sr->selectedArtisan->user->name,
                        'first_name' => $sr->selectedArtisan->user->first_name,
                    ] : null,
                    'request_reference' => $sr ? substr((string) $sr->getKey(), -6) : null,
                ];
            })->values(),
        ]);
    }
}