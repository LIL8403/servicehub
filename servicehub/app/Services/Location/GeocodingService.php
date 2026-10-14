<?php

namespace App\Services\Location;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use InvalidArgumentException;
use Throwable;

/**
 * Geocodes free-text addresses and reverse-geocodes coordinates using
 * OpenStreetMap's Nominatim service.
 *
 * Nominatim is free, requires a descriptive User-Agent, and asks for a
 * maximum request rate of 1 per second. The existing cache layer keeps
 * us well under that threshold.
 *
 * The public interface is unchanged from the earlier Google-backed
 * implementation, so no caller needs to be modified.
 */
class GeocodingService
{
    public function geocode(string $address): ?array
    {
        $address = $this->normalizeAddress($address);

        if ($address === '') {
            return null;
        }

        $cacheKey = 'nominatim:geocode:' . hash('sha256', strtolower($address));

        if (($cached = Cache::get($cacheKey)) !== null) {
            return is_array($cached) ? $cached : null;
        }

        $result = $this->request('search', [
            'q' => $address,
            'format' => 'json',
            'limit' => 1,
            'addressdetails' => 1,
            'countrycodes' => config('services.nominatim.country_codes', 'cm'),
        ]);

        if ($result !== null) {
            Cache::put($cacheKey, $result, now()->addSeconds($this->cacheTtl()));
        }

        return $result;
    }

    public function reverseGeocode(float $latitude, float $longitude): ?array
    {
        if (! $this->coordinatesAreValid($latitude, $longitude)) {
            return null;
        }

        $coordinates = sprintf('%.6F,%.6F', $latitude, $longitude);
        $cacheKey = 'nominatim:reverse_geocode:' . hash('sha256', $coordinates);

        if (($cached = Cache::get($cacheKey)) !== null) {
            return is_array($cached) ? $cached : null;
        }

        $result = $this->request('reverse', [
            'lat' => $latitude,
            'lon' => $longitude,
            'format' => 'json',
            'addressdetails' => 1,
        ]);

        if ($result !== null) {
            Cache::put($cacheKey, $result, now()->addSeconds($this->cacheTtl()));
        }

        return $result;
    }

    /**
     * Convert latitude/longitude to the GeoJSON format required by
     * MongoDB. MongoDB coordinates are ordered as [longitude, latitude].
     */
    public function toGeoJson(float $latitude, float $longitude): array
    {
        if (! $this->coordinatesAreValid($latitude, $longitude)) {
            throw new InvalidArgumentException('Latitude or longitude is outside its valid range.');
        }

        return [
            'type' => 'Point',
            'coordinates' => [$longitude, $latitude],
        ];
    }

    /**
     * Perform a Nominatim request. Nominatim returns an array for
     * /search and an object for /reverse; we normalize both into the
     * same shape our callers expect.
     */
    private function request(string $operation, array $parameters): ?array
    {
        if (! $this->isAvailable()) {
            Log::notice('Nominatim geocoding was skipped because it is not configured.', [
                'operation' => $operation,
            ]);

            return null;
        }

        try {
            $response = Http::acceptJson()
                ->withHeaders([
                    'User-Agent' => $this->userAgent(),
                ])
                ->connectTimeout(2)
                ->timeout(5)
                ->get($this->baseUrl() . '/' . $operation, $parameters);
        } catch (Throwable $e) {
            Log::warning('Nominatim geocoding request could not be completed.', [
                'operation' => $operation,
                'reason' => 'connection_failure',
                'message' => $e->getMessage(),
            ]);

            return null;
        }

        if (! $response->successful()) {
            Log::warning('Nominatim geocoding returned a non-success response.', [
                'operation' => $operation,
                'http_status' => $response->status(),
            ]);

            return null;
        }

        $payload = $response->json();

        // Normalize the two response shapes.
        $entry = null;
        if (is_array($payload)) {
            $entry = $operation === 'reverse'
                ? (isset($payload['lat']) ? $payload : null)
                : (isset($payload[0]) ? $payload[0] : null);
        }

        if (
            ! is_array($entry)
            || ! is_numeric($entry['lat'] ?? null)
            || ! is_numeric($entry['lon'] ?? null)
            || ! is_string($entry['display_name'] ?? null)
        ) {
            Log::warning('Nominatim geocoding returned an invalid payload.', [
                'operation' => $operation,
            ]);

            return null;
        }

        $latitude = (float) $entry['lat'];
        $longitude = (float) $entry['lon'];

        if (! $this->coordinatesAreValid($latitude, $longitude)) {
            return null;
        }

        return [
            'latitude' => $latitude,
            'longitude' => $longitude,
            'formatted_address' => $entry['display_name'],
        ];
    }

    private function isAvailable(): bool
    {
        $enabled = config('services.nominatim.geocoding_enabled') !== false;
        $hasUrl = filled(config('services.nominatim.base_url'));

        if (! $enabled || ! $hasUrl) {
            Log::notice('Nominatim isAvailable() is false.', [
                'enabled' => $enabled,
                'hasUrl' => $hasUrl,
                'raw_enabled_value' => config('services.nominatim.geocoding_enabled'),
                'raw_url_value' => config('services.nominatim.base_url'),
            ]);
        }

        return $enabled && $hasUrl;
    }

    private function baseUrl(): string
    {
        return rtrim((string) config(
            'services.nominatim.base_url',
            'https://nominatim.openstreetmap.org'
        ), '/');
    }

    private function userAgent(): string
    {
        return (string) config(
            'services.nominatim.user_agent',
            'ServiceHUB/1.0 (contact: hello@servicehub.cm)'
        );
    }

    private function cacheTtl(): int
    {
        return max(1, min((int) config('services.nominatim.cache_ttl', 86400), 604800));
    }

    private function normalizeAddress(string $address): string
    {
        return trim((string) preg_replace('/\s+/', ' ', $address));
    }

    private function coordinatesAreValid(float $latitude, float $longitude): bool
    {
        return $latitude >= -90 && $latitude <= 90 && $longitude >= -180 && $longitude <= 180;
    }
}
