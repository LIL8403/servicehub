<?php

namespace App\Http\Controllers\Api;

use App\Enums\VerificationStatus;
use App\Http\Controllers\Controller;
use App\Models\Artisan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ArtisanDiscoveryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'service_id' => ['nullable', 'string'],
            'area' => ['nullable', 'string', 'max:255'],
            'min_experience_years' => ['nullable', 'integer', 'min:0', 'max:60'],
            'available' => ['nullable', 'boolean'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180', 'required_with:latitude,radius_km'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90', 'required_with:longitude,radius_km'],
            'radius_km' => ['nullable', 'numeric', 'min:1', 'max:100', 'required_with:longitude,latitude'],
        ]);

        $query = [
            'verification_status' => VerificationStatus::VERIFIED->value,
        ];

        // Only filter by service when a service_id was provided.
        if (! empty($filters['service_id'])) {
            $query['service_offerings'] = ['$elemMatch' => [
                'service_reference' => $filters['service_id'],
                'is_active' => true,
            ]];
        }

        if (isset($filters['min_experience_years'])) {
            $query['experience_years'] = ['$gte' => $filters['min_experience_years']];
        }

        if (isset($filters['area'])) {
            $query['service_areas'] = $filters['area'];
        }

        if (($filters['available'] ?? false) === true) {
            $query['availability.accepting_requests'] = true;
        }

        if (isset($filters['longitude'])) {
            $query['location'] = ['$near' => [
                '$geometry' => [
                    'type' => 'Point',
                    'coordinates' => [
                        (float) $filters['longitude'],
                        (float) $filters['latitude'],
                    ],
                ],
                '$maxDistance' => (float) $filters['radius_km'] * 1000,
            ]];
        }

        $profiles = Artisan::whereRaw($query);

        if (! isset($filters['longitude'])) {
            $profiles->orderBy('rating_average', 'desc');
        }

        $profiles = $profiles->get();

        return response()->json([
            'artisans' => $profiles->map(function (Artisan $profile) use ($filters) {
                $offerings = collect($profile->service_offerings ?? []);

                if (! empty($filters['service_id'])) {
                    $offerings = $offerings
                        ->where('service_reference', $filters['service_id'])
                        ->where('is_active', true)
                        ->values();
                }

                return [
                    'id' => (string) $profile->getKey(),
                    'professional_title' => $profile->professional_title,
                    'professional_description' => $profile->professional_description ?? $profile->bio,
                    'bio' => $profile->bio,
                    'experience_years' => $profile->experience_years,
                    'service_areas' => $profile->service_areas ?? [],
                    'availability' => $profile->availability ?? [],
                    'location' => $profile->location ?? $profile->service_location,
                    'rating_average' => (float) ($profile->rating_average ?? 0),
                    'review_count' => (int) ($profile->review_count ?? 0),
                    'completed_jobs' => (int) ($profile->completed_jobs ?? 0),
                    'response_rate' => (float) ($profile->response_rate ?? 0),
                    'languages' => $profile->languages ?? [],
                    'certifications' => $profile->certifications ?? [],
                    'verification_status' => $profile->verification_status?->value ?? 'unverified',
                    'service_offerings' => $offerings,
                    'user' => $profile->user ? [
                        'id' => (string) $profile->user->getKey(),
                        'name' => $profile->user->name,
                        'first_name' => $profile->user->first_name,
                        'last_name' => $profile->user->last_name,
                        'has_photo' => ! empty($profile->user->profile_photo),
                    ] : null,
                ];
            })->values(),
        ]);
    }
}