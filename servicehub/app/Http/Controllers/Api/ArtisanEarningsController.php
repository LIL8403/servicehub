<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ArtisanEarningsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ArtisanEarningsController extends Controller
{
    public function __construct(
        private readonly ArtisanEarningsService $earnings,
    ) {}

    public function summary(Request $request): JsonResponse
    {
        $artisan = $request->user()->artisan()->first();
        abort_unless($artisan, 404, 'Artisan profile not found.');

        return response()->json([
            'summary' => $this->earnings->summary($artisan),
        ]);
    }

    public function payouts(Request $request): JsonResponse
    {
        $artisan = $request->user()->artisan()->first();
        abort_unless($artisan, 404, 'Artisan profile not found.');

        $page = max(1, (int) $request->query('page', 1));
        $perPage = min(50, max(5, (int) $request->query('per_page', 20)));

        return response()->json(
            $this->earnings->payouts($artisan, $page, $perPage)
        );
    }
}