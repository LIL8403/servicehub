<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Review\StoreReviewRequest;
use App\Models\ServiceRequest;
use App\Services\ReviewService;
use Illuminate\Http\JsonResponse;

class ReviewController extends Controller
{
    public function __construct(private readonly ReviewService $reviews) {}

    public function store(StoreReviewRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $data = $request->validated();

        // Attach uploaded photos as storage records, then strip the
        // file objects from the validated data before handing it to the
        // service. Photos are stored under the 'reviews' disk prefix.
        $photos = [];
        if (! empty($data['photos'])) {
            foreach ($data['photos'] as $file) {
                $path = $file->store('reviews/photos', 'local');
                $photos[] = [
                    'id' => (string) \Illuminate\Support\Str::uuid(),
                    'path' => $path,
                    'name' => $file->getClientOriginalName(),
                    'mime_type' => $file->getClientMimeType() ?? 'image/jpeg',
                    'size' => $file->getSize() ?? 0,
                ];
            }
        }
        $data['photos'] = $photos;

        return response()->json([
            'review' => $this->reviews->create($serviceRequest, $request->user(), $data),
        ], 201);
    }
}