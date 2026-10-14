<?php

use App\Enums\ServiceRequestStatus;
use App\Models\Review;
use App\Models\ServiceRequest;
use Illuminate\Foundation\Testing\DatabaseMigrations;

uses(DatabaseMigrations::class);

it('allows the customer to review a completed request once and updates artisan reputation', function () {
    $customer = requestCustomer('review-owner@example.test');
    $service = requestService();
    $artisan = eligibleRequestArtisan($service);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(), 'service_id' => $service->getKey(), 'selected_artisan_id' => $artisan->getKey(),
        'description' => 'Completed plumbing repair.', 'location' => ['type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::COMPLETED, 'status_history' => [],
    ]);

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/reviews", ['rating' => 5, 'comment' => 'Reliable and professional.'])
        ->assertCreated()->assertJsonPath('review.rating', 5);

    expect(Review::count())->toBe(1);
    expect($artisan->fresh()->rating_average)->toBe(5.0)->and($artisan->fresh()->review_count)->toBe(1);

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/reviews", ['rating' => 4])
        ->assertUnprocessable()->assertJsonValidationErrors('service_request');
});

it('does not allow a review before request completion', function () {
    $customer = requestCustomer('review-pending@example.test');
    $service = requestService();
    $artisan = eligibleRequestArtisan($service);
    $request = ServiceRequest::create([
        'customer_id' => $customer->getKey(), 'service_id' => $service->getKey(), 'selected_artisan_id' => $artisan->getKey(),
        'description' => 'Pending plumbing repair.', 'location' => ['type' => 'Point', 'coordinates' => [11.5, 3.8]],
        'status' => ServiceRequestStatus::IN_PROGRESS, 'status_history' => [],
    ]);

    $this->actingAs($customer, 'sanctum')->postJson("/api/customer/service-requests/{$request->getKey()}/reviews", ['rating' => 5])
        ->assertUnprocessable()->assertJsonValidationErrors('service_request');
});
