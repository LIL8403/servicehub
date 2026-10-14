<?php

namespace App\Jobs;

use App\Models\Payment;
use App\Services\Ai\AiOrchestrationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class DetectPaymentAnomalyJob implements ShouldQueue
{
    use Queueable;

    public int $timeout = 10;

    public function __construct(public readonly string $paymentId) {}

    public function handle(AiOrchestrationService $ai): void
    {
        $payment = Payment::query()->find($this->paymentId);
        if ($payment) {
            $ai->detectPaymentAnomaly($payment);
        }
    }
}
