<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Payment\InitiatePaymentRequest;
use App\Jobs\DetectPaymentAnomalyJob;
use App\Models\Payment;
use App\Models\ServiceRequest;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(private readonly PaymentService $paymentService) {}

    public function initiate(InitiatePaymentRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $payment = $this->paymentService->initiate(
            $serviceRequest,
            $request->user(),
            $request->validated('phone'),
            $request->validated('idempotency_key'),
            $request->validated('provider'),
        );

        DetectPaymentAnomalyJob::dispatch($payment->getKey());

        return response()->json(['payment' => $payment], 201);
    }

    public function reconcile(Request $request, Payment $payment): JsonResponse
    {
        return response()->json(['payment' => $this->paymentService->reconcile($payment, $request->user())]);
    }
}