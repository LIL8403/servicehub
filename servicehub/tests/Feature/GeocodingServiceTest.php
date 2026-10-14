<?php

use App\Services\Location\GeocodingService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;

beforeEach(function () {
    Cache::flush();

    Config::set('services.google_maps', [
        'base_url' => 'https://maps.googleapis.com/maps/api/geocode/json',
        'key' => 'test-server-key',
        'geocoding_enabled' => true,
        'cache_ttl' => 86400,
        'region' => 'cm',
    ]);
});

it('geocodes a Cameroon-biased address and caches a successful result', function () {
    Http::fake([
        'https://maps.googleapis.com/maps/api/geocode/json*' => Http::response([
            'status' => 'OK',
            'results' => [[
                'formatted_address' => 'Bastos, Yaounde, Cameroon',
                'geometry' => ['location' => ['lat' => 3.8992, 'lng' => 11.5174]],
            ]],
        ]),
    ]);

    $service = app(GeocodingService::class);

    expect($service->geocode(' Bastos,  Yaounde '))->toBe([
        'latitude' => 3.8992,
        'longitude' => 11.5174,
        'formatted_address' => 'Bastos, Yaounde, Cameroon',
    ]);
    expect($service->geocode('Bastos, Yaounde'))->toBe([
        'latitude' => 3.8992,
        'longitude' => 11.5174,
        'formatted_address' => 'Bastos, Yaounde, Cameroon',
    ]);

    Http::assertSent(function ($request) {
        return $request->url() === 'https://maps.googleapis.com/maps/api/geocode/json?address=Bastos%2C%20Yaounde&region=cm&key=test-server-key';
    });
    Http::assertSentCount(1);
});

it('reverse geocodes latitude and longitude', function () {
    Http::fake([
        'https://maps.googleapis.com/maps/api/geocode/json*' => Http::response([
            'status' => 'OK',
            'results' => [[
                'formatted_address' => 'Bastos, Yaounde, Cameroon',
                'geometry' => ['location' => ['lat' => 3.8992, 'lng' => 11.5174]],
            ]],
        ]),
    ]);

    $result = app(GeocodingService::class)->reverseGeocode(3.8992, 11.5174);

    expect($result['formatted_address'])->toBe('Bastos, Yaounde, Cameroon');
    expect($result['latitude'])->toBe(3.8992);
    expect($result['longitude'])->toBe(11.5174);
});

it('fails safely when Google Maps returns no usable result', function () {
    Http::fake([
        'https://maps.googleapis.com/maps/api/geocode/json*' => Http::response([
            'status' => 'ZERO_RESULTS',
            'results' => [],
        ]),
    ]);

    expect(app(GeocodingService::class)->geocode('Unknown place in Cameroon'))->toBeNull();
});

it('converts valid coordinates to GeoJSON and rejects invalid coordinates', function () {
    $service = app(GeocodingService::class);

    expect($service->toGeoJson(3.8992, 11.5174))->toBe([
        'type' => 'Point',
        'coordinates' => [11.5174, 3.8992],
    ]);
    expect(fn () => $service->toGeoJson(91, 11.5174))->toThrow(InvalidArgumentException::class);
});
