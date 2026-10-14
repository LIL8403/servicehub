<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Artisan\StoreServiceOfferingRequest;
use App\Http\Requests\Artisan\UpdateServiceOfferingRequest;
use App\Models\Service;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ArtisanServiceOfferingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $profile = $this->profile($request);
        $offerings = collect($profile->service_offerings ?? [])
            ->map(function (array $offering) {
                // Backfill `offering_id` on legacy seeder entries so
                // the frontend can address them for edit/pause/remove.
                if (! isset($offering['offering_id'])) {
                    $offering['offering_id'] = (string) Str::uuid();
                }

                // Normalize to also expose `service_id` alongside
                // `service_reference` for the frontend model.
                $offering['service_id'] = $offering['service_reference']
                    ?? $offering['service_id']
                    ?? null;

                return $offering;
            })
            ->values()
            ->all();

        // Persist the backfilled ids so subsequent calls are stable.
        if ($offerings !== ($profile->service_offerings ?? [])) {
            $profile->update(['service_offerings' => $offerings]);
        }

        return response()->json(['offerings' => $offerings]);
    }

    public function store(StoreServiceOfferingRequest $request): JsonResponse
    {
        $profile = $this->profile($request);
        $data = $request->validated();
        Service::query()->where('_id', $data['service_id'])->where('is_active', true)->firstOrFail();
        $offerings = $profile->service_offerings ?? [];

        abort_if(collect($offerings)->contains('service_reference', $data['service_id']), 422, 'This service is already offered.');

        $offering = [
            'offering_id' => (string) Str::uuid(),
            'service_reference' => $data['service_id'],
            'starting_price' => $data['starting_price'] ?? null,
            'description' => $data['description'] ?? null,
            'is_active' => $data['is_active'] ?? true,
        ];

        $profile->update(['service_offerings' => [...$offerings, $offering]]);

        return response()->json(['offering' => [...$offering, 'service_id' => $offering['service_reference']]], 201);
    }

    public function update(UpdateServiceOfferingRequest $request, string $offeringId): JsonResponse
    {
        $profile = $this->profile($request);
        $found = false;

        $offerings = collect($profile->service_offerings ?? [])
            ->map(function (array $offering) use ($request, $offeringId, &$found) {
                // Legacy entries created by the demo seeder have no
                // `offering_id`. Backfill on the fly so they can still
                // be edited — we assign a fresh id the first time the
                // row is touched.
                if (! isset($offering['offering_id'])) {
                    $offering['offering_id'] = (string) Str::uuid();
                }

                if ($offering['offering_id'] === $offeringId) {
                    $found = true;

                    return [...$offering, ...$request->validated()];
                }

                return $offering;
            })
            ->values()
            ->all();

        abort_unless($found, 404);
        $profile->update(['service_offerings' => $offerings]);

        return response()->json([
            'offering' => collect($offerings)->firstWhere('offering_id', $offeringId),
        ]);
    }

    public function destroy(Request $request, string $offeringId): JsonResponse
    {
        $profile = $this->profile($request);
        $offerings = $profile->service_offerings ?? [];

        $remaining = collect($offerings)
            ->reject(function (array $offering) use ($offeringId) {
                // Skip legacy entries that have no id — they can't
                // match a client-supplied offeringId anyway.
                if (! isset($offering['offering_id'])) {
                    return false;
                }

                return $offering['offering_id'] === $offeringId;
            })
            ->values()
            ->all();

        abort_if(count($remaining) === count($offerings), 404);
        $profile->update(['service_offerings' => $remaining]);

        return response()->json(status: 204);
    }

    private function profile(Request $request)
    {
        return $request->user()->artisan()->firstOrFail();
    }
}
