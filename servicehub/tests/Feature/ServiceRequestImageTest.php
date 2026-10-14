<?php

use App\Enums\ServiceRequestStatus;
use App\Enums\VerificationStatus;
use App\Models\ArtisanProfile;
use App\Models\Service;
use App\Models\ServiceCategory;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

uses(DatabaseMigrations::class);

function imageRequestCustomer(string $email): User
{
    return User::create([
        'name' => 'Image Request Customer',
        'email' => $email,
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['customer'],
    ]);
}

function imageRequestService(): Service
{
    $suffix = uniqid();
    $category = ServiceCategory::create([
        'name' => 'Image Request Category '.$suffix,
        'slug' => 'image-request-category-'.$suffix,
        'is_active' => true,
    ]);

    return Service::create([
        'service_category_id' => $category->getKey(),
        'name' => 'Image Request Service '.$suffix,
        'slug' => 'image-request-service-'.$suffix,
        'is_active' => true,
    ]);
}

function imageRequestPayload(Service $service): array
{
    return [
        'service_id' => $service->getKey(),
        'description' => 'A damaged water pipe needs an urgent repair assessment.',
        'location' => [
            'label' => 'Bastos, Yaounde',
            'type' => 'Point',
            'coordinates' => [11.5174, 3.8992],
        ],
    ];
}

it('stores request images privately and returns only safe metadata', function () {
    Storage::fake('local');
    $customer = imageRequestCustomer('image-owner@example.test');
    $service = imageRequestService();
    $image = UploadedFile::fake()->image('leaking-pipe.jpg', 640, 480);

    $response = $this->withHeader('Accept', 'application/json')
        ->withToken($customer->createToken('test')->plainTextToken)
        ->post('/api/customer/service-requests', [
            ...imageRequestPayload($service),
            'images' => [$image],
        ]);

    $response->assertCreated()
        ->assertJsonPath('service_request.image_attachments.0.name', 'leaking-pipe.jpg')
        ->assertJsonPath('service_request.image_attachments.0.mime_type', 'image/jpeg')
        ->assertJsonMissingPath('service_request.images');

    $serviceRequest = ServiceRequest::findOrFail($response->json('service_request.id'));
    $attachment = $serviceRequest->images[0];
    Storage::disk('local')->assertExists($attachment['path']);

    $this->withToken($customer->createToken('download')->plainTextToken)
        ->get("/api/customer/service-requests/{$serviceRequest->getKey()}/images/{$attachment['id']}")
        ->assertOk();
});

it('rejects unsafe request-image types and prevents unrelated users from downloading images', function () {
    Storage::fake('local');
    $customer = imageRequestCustomer('image-validation-owner@example.test');
    $outsider = imageRequestCustomer('image-validation-outsider@example.test');
    $service = imageRequestService();

    $this->withHeader('Accept', 'application/json')
        ->withToken($customer->createToken('unsafe')->plainTextToken)
        ->post('/api/customer/service-requests', [
            ...imageRequestPayload($service),
            'images' => [UploadedFile::fake()->create('unsafe.exe', 20, 'application/octet-stream')],
        ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('images.0');

    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(),
        'service_id' => $service->getKey(),
        'description' => 'A private image download authorization scenario.',
        'location' => ['type' => 'Point', 'coordinates' => [11.5174, 3.8992]],
        'status' => ServiceRequestStatus::AWAITING_ARTISAN_SELECTION,
        'status_history' => [],
        'images' => [[
            'id' => 'private-image-id',
            'path' => 'service-requests/private-request/private.jpg',
            'name' => 'private.jpg',
            'mime_type' => 'image/jpeg',
            'size' => 12,
        ]],
    ]);
    Storage::disk('local')->put($request->images[0]['path'], 'private-image');

    $this->actingAs($outsider, 'sanctum')
        ->get("/api/customer/service-requests/{$request->getKey()}/images/private-image-id")
        ->assertNotFound();
});

it('allows only the selected artisan to download a request image', function () {
    Storage::fake('local');
    $customer = imageRequestCustomer('image-artisan-owner@example.test');
    $artisanUser = User::create([
        'name' => 'Image Request Artisan',
        'email' => 'image-request-artisan@example.test',
        'phone' => '677'.random_int(100000, 999999),
        'password' => 'A-secure-password1',
        'roles' => ['artisan'],
    ]);
    $service = imageRequestService();
    $artisan = ArtisanProfile::create([
        'user_id' => $artisanUser->getKey(),
        'professional_title' => 'Plumber',
        'verification_status' => VerificationStatus::VERIFIED,
        'service_offerings' => [[
            'offering_id' => 'image-request-offering',
            'service_reference' => $service->getKey(),
            'is_active' => true,
        ]],
    ]);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(),
        'service_id' => $service->getKey(),
        'selected_artisan_id' => $artisan->getKey(),
        'description' => 'An artisan needs access to this selected request image.',
        'location' => ['type' => 'Point', 'coordinates' => [11.5174, 3.8992]],
        'status' => ServiceRequestStatus::ARTISAN_APPROVED,
        'status_history' => [],
        'images' => [[
            'id' => 'artisan-image-id',
            'path' => 'service-requests/artisan-request/pipe.jpg',
            'name' => 'pipe.jpg',
            'mime_type' => 'image/jpeg',
            'size' => 12,
        ]],
    ]);
    Storage::disk('local')->put($request->images[0]['path'], 'artisan-image');

    $this->withToken($artisanUser->createToken('artisan-download')->plainTextToken)
        ->get("/api/artisan/service-requests/{$request->getKey()}/images/artisan-image-id")
        ->assertOk();
});
