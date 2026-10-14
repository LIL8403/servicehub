<?php

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;

uses(DatabaseMigrations::class);

function geocodingRequestCustomer(): User
{
    return User::create([
        'name' => 'Geocoding Customer',
        'email' => 'geocoding-customer-'.uniqid().'@example.test',
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);
}

function geocodingRequestService(): Service
{
    $suffix = uniqid();
    $category = ServiceCategory::create([
        'name' => 'Geocoding Category '.$suffix,
        'slug' => 'geocoding-category-'.$suffix,
        'is_active' => true,
    ]);

    return Service::create([
        'service_category_id' => $category->getKey(),
        'name' => 'Geocoding Service '.$suffix,
        'slug' => 'geocoding-service-'.$suffix,
        'is_active' => true,
    ]);
}

function configureGoogleMapsForRequestTests(bool $enabled = true): void
{
    Config::set('services.google_maps', [
        'base_url' => 'https://maps.googleapis.com/maps/api/geocode/json',
        'key' => $enabled ? 'test-server-key' : null,
        'geocoding_enabled' => $enabled,
        'cache_ttl' => 86400,
        'region' => 'cm',
    ]);
}

function geocodingRequestPayload(Service $service): array
{
    return [
        'service_id' => $service->getKey(),
        'description' => 'A water pipe is leaking under the kitchen sink.',
    ];
}

it('creates a request from a typed address using server-side geocoding', function () {
    configureGoogleMapsForRequestTests();
    Http::fake([
        'https://maps.googleapis.com/maps/api/geocode/json*' => Http::response([
            'status' => 'OK',
            'results' => [[
                'formatted_address' => 'Bastos, Yaounde, Cameroon',
                'geometry' => ['location' => ['lat' => 3.8992, 'lng' => 11.5174]],
            ]],
        ]),
    ]);
    $customer = geocodingRequestCustomer();
    $service = geocodingRequestService();

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->postJson('/api/customer/service-requests', [
            ...geocodingRequestPayload($service),
            'address' => 'Bastos, Yaounde',
        ])
        ->assertCreated()
        ->assertJsonPath('service_request.location.type', 'Point')
        ->assertJsonPath('service_request.location.coordinates.0', 11.5174)
        ->assertJsonPath('service_request.location.coordinates.1', 3.8992)
        ->assertJsonPath('service_request.location.label', 'Bastos, Yaounde, Cameroon')
        ->assertJsonPath('service_request.formatted_address', 'Bastos, Yaounde, Cameroon');
});

it('creates a request from valid manual coordinates when geocoding is unavailable', function () {
    configureGoogleMapsForRequestTests(false);
    Http::fake();
    $customer = geocodingRequestCustomer();
    $service = geocodingRequestService();

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->postJson('/api/customer/service-requests', [
            ...geocodingRequestPayload($service),
            'address' => 'This text must not call Google Maps',
            'location' => [
                'label' => 'Manual pin in Yaounde',
                'type' => 'Point',
                'coordinates' => [11.5174, 3.8992],
            ],
        ])
        ->assertCreated()
        ->assertJsonPath('service_request.location.label', 'Manual pin in Yaounde');

    Http::assertNothingSent();
});

it('asks for a manual pin when an address-only lookup fails', function () {
    configureGoogleMapsForRequestTests();
    Http::fake([
        'https://maps.googleapis.com/maps/api/geocode/json*' => Http::response([
            'status' => 'ZERO_RESULTS',
            'results' => [],
        ]),
    ]);
    $customer = geocodingRequestCustomer();
    $service = geocodingRequestService();

    $this->withToken($customer->createToken('test')->plainTextToken)
        ->postJson('/api/customer/service-requests', [
            ...geocodingRequestPayload($service),
            'address' => 'Unknown location in Cameroon',
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('address');
});
