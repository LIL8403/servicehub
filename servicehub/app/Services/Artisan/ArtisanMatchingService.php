<?php

namespace App\Services\Artisan;

use App\Enums\AccountStatus;
use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\Artisan;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Support\Collection;

class ArtisanMatchingService
{
    /** @return Collection<int, Artisan> */
    public function findEligibleArtisans(ServiceRequest $request): Collection
    {
        return $this->categoryArtisans($request)
            ->filter(fn(Artisan $artisan) => $artisan->verification_status === VerificationStatus::VERIFIED)
            ->filter(fn(Artisan $artisan) => $this->hasActiveAccount($artisan))
            ->filter(fn(Artisan $artisan) => $this->servesRequestLocation($artisan, $request))
            ->filter(fn(Artisan $artisan) => ! $this->isBooked($artisan, $request))
            ->values();
    }

    public function countEligibleArtisans(ServiceRequest $request): int
    {
        return $this->findEligibleArtisans($request)->count();
    }

    public function reasonForNoMatch(ServiceRequest $request): string
    {
        $categoryArtisans = $this->categoryArtisans($request);

        if ($categoryArtisans->isEmpty()) {
            return 'no_artisans_in_category';
        }

        $verified = $categoryArtisans->filter(fn(Artisan $artisan) => $artisan->verification_status === VerificationStatus::VERIFIED);
        if ($verified->isEmpty()) {
            return 'no_verified_artisans_in_category';
        }

        $active = $verified->filter(fn(Artisan $artisan) => $this->hasActiveAccount($artisan));
        if ($active->isNotEmpty() && $active->every(fn(Artisan $artisan) => ! $this->servesRequestLocation($artisan, $request))) {
            return 'no_artisans_in_location';
        }

        $locationMatches = $active->filter(fn(Artisan $artisan) => $this->servesRequestLocation($artisan, $request));
        if ($locationMatches->isNotEmpty() && $locationMatches->every(fn(Artisan $artisan) => $this->isBooked($artisan, $request))) {
            return 'all_artisans_booked';
        }

        return 'no_matching_artisans';
    }

    /** @return Collection<int, Artisan> */
    private function categoryArtisans(ServiceRequest $request): Collection
    {
        return Artisan::query()->get()->filter(function (Artisan $artisan) use ($request): bool {
            return collect($artisan->service_offerings ?? [])->contains(
                fn(array $offering) => ($offering['service_reference'] ?? null) === $request->service_id
                    && ($offering['is_active'] ?? false) === true,
            );
        })->values();
    }

    private function hasActiveAccount(Artisan $artisan): bool
    {
        $user = User::query()->find($artisan->user_id);

        return $user !== null && $user->account_status === AccountStatus::ACTIVE;
    }

    private function servesRequestLocation(Artisan $artisan, ServiceRequest $request): bool
    {
        $requestLabel = $this->normalizeString(
            (string) (data_get($request->location, 'label') ?? $request->formatted_address ?? '')
        );

        // --- Location name match ---
        $areas = collect($artisan->service_areas ?? [])->map(function ($area) {
            if (is_array($area)) {
                return $this->normalizeString((string) ($area['city'] ?? ''));
            }
            return $this->normalizeString((string) $area);
        })->filter()->values();

        if ($requestLabel !== '' && $areas->isNotEmpty()) {
            foreach ($areas as $area) {
                if ($area === '') continue;

                // Exact match
                if ($area === $requestLabel) return true;

                // Word overlap: "yaounde bastos" contains "yaounde"
                $requestWords = preg_split('/\s+/', $requestLabel) ?: [];
                $areaWords = preg_split('/\s+/', $area) ?: [];

                foreach ($requestWords as $rWord) {
                    foreach ($areaWords as $aWord) {
                        if ($rWord === '' || $aWord === '') continue;
                        if ($rWord === $aWord) return true;
                        if (strlen($rWord) >= 4 && str_contains($aWord, $rWord)) return true;
                        if (strlen($aWord) >= 4 && str_contains($rWord, $aWord)) return true;
                    }
                }
            }
        }

        // --- Geospatial match ---
        $artisanCoordinates = data_get($artisan->location, 'coordinates')
            ?? data_get($artisan->service_location, 'coordinates');
        $requestCoordinates = data_get($request->location, 'coordinates');

        $radius = data_get($artisan->availability, 'radius_km')
            ?? data_get($artisan->availability, 'service_radius_km');

        // Fallback: pick the largest radius from service_areas[*].radius_km
        if (! is_numeric($radius)) {
            $radius = collect($artisan->service_areas ?? [])
                ->pluck('radius_km')
                ->filter(fn($v) => is_numeric($v))
                ->max();
        }

        if (
            ! is_array($artisanCoordinates) || ! is_array($requestCoordinates)
            || ! is_numeric($radius)
            || count($artisanCoordinates) !== 2
            || count($requestCoordinates) !== 2
        ) {
            return false;
        }

        return $this->distanceKilometres(
            (float) $artisanCoordinates[1],
            (float) $artisanCoordinates[0],
            (float) $requestCoordinates[1],
            (float) $requestCoordinates[0],
        ) <= (float) $radius;
    }

    private function normalizeString(string $value): string
    {
        $value = mb_strtolower(trim($value));

        return strtr($value, [
            'à' => 'a',
            'â' => 'a',
            'ä' => 'a',
            'á' => 'a',
            'ã' => 'a',
            'å' => 'a',
            'é' => 'e',
            'è' => 'e',
            'ê' => 'e',
            'ë' => 'e',
            'î' => 'i',
            'ï' => 'i',
            'í' => 'i',
            'ô' => 'o',
            'ö' => 'o',
            'ó' => 'o',
            'õ' => 'o',
            'ù' => 'u',
            'û' => 'u',
            'ü' => 'u',
            'ú' => 'u',
            'ç' => 'c',
            'ñ' => 'n',
        ]);
    }

    private function isBooked(Artisan $artisan, ServiceRequest $request): bool
    {
        if (data_get($artisan->availability, 'accepting_requests') === false) {
            return true;
        }

        $date = data_get($request->preferred_schedule, 'date');
        if (! $date) {
            return false;
        }

        if (in_array($date, data_get($artisan->availability, 'booked_dates', []), true)) {
            return true;
        }

        return ServiceRequest::query()->where('selected_artisan_id', $artisan->getKey())->get()->contains(function (ServiceRequest $existing) use ($date): bool {
            return data_get($existing->preferred_schedule, 'date') === $date
                && in_array($existing->status, [ServiceRequestStatus::BOOKED, ServiceRequestStatus::IN_PROGRESS, ServiceRequestStatus::AWAITING_CONFIRMATION], true);
        });
    }

    private function distanceKilometres(float $latitudeA, float $longitudeA, float $latitudeB, float $longitudeB): float
    {
        $earthRadiusKm = 6371.0;
        $deltaLatitude = deg2rad($latitudeB - $latitudeA);
        $deltaLongitude = deg2rad($longitudeB - $longitudeA);
        $a = sin($deltaLatitude / 2) ** 2 + cos(deg2rad($latitudeA)) * cos(deg2rad($latitudeB)) * sin($deltaLongitude / 2) ** 2;

        return $earthRadiusKm * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
