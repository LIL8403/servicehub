<?php

namespace App\Services;

use App\Enums\ServiceRequestStatus;
use App\Models\Review;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class ReviewService
{
    public function create(ServiceRequest $request, User $customer, array $data): Review
    {
        abort_unless($request->customer_id === $customer->getKey(), 404);
        if ($request->status !== ServiceRequestStatus::COMPLETED) {
            throw ValidationException::withMessages(['service_request' => ['Only completed service requests can be reviewed.']]);
        }
        if (Review::query()->where('service_request_id', $request->getKey())->exists()) {
            throw ValidationException::withMessages(['service_request' => ['This service request has already been reviewed.']]);
        }

        $review = Review::create([...$data, 'service_request_id' => $request->getKey(), 'customer_id' => $customer->getKey(), 'artisan_profile_id' => $request->selected_artisan_id]);
        $artisan = $request->selectedArtisan()->firstOrFail();
        $reviews = Review::query()->where('artisan_profile_id', $artisan->getKey())->get();
        $artisan->update(['review_count' => $reviews->count(), 'rating_average' => round($reviews->avg('rating'), 2)]);

        return $review;
    }
}
