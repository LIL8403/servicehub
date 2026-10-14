<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateCommissionRateRequest;
use App\Services\Platform\PlatformSettingsService;
use Illuminate\Http\JsonResponse;

class PlatformSettingsController extends Controller
{
    public function __construct(private readonly PlatformSettingsService $settings) {}

    public function commission(): JsonResponse
    {
        return response()->json([
            'commission_rate' => $this->settings->getCommissionRate(),
            'minimum' => 0.0,
            'maximum' => 0.30,
        ]);
    }

    public function updateCommission(UpdateCommissionRateRequest $request): JsonResponse
    {
        $this->settings->updateCommissionRate((float) $request->validated('rate'), $request->user()->getKey(), $request->validated('reason'));

        return response()->json(['commission_rate' => $this->settings->getCommissionRate()]);
    }
}
