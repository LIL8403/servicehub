<?php

namespace App\Jobs;

use App\Models\ServiceRequest;
use App\Services\Ai\AiOrchestrationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class AnalyzeQuotationJob implements ShouldQueue
{
    use Queueable;

    public int $timeout = 10;

    public function __construct(public readonly string $serviceRequestId) {}

    public function handle(AiOrchestrationService $ai): void
    {
        $request = ServiceRequest::query()->find($this->serviceRequestId);
        if ($request) {
            $ai->analyzeQuotation($request);
        }
    }
}
