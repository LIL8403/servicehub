<?php

namespace Database\Seeders;

use App\Models\Review;
use App\Models\ServiceRequest;
use Illuminate\Database\Seeder;

/**
 * Sample reviews, attached to completed service requests.
 *
 * Why requests first: the `reviews` collection has a unique index on
 * `service_request_id`, so every review must reference a real request.
 * The seeder picks only the completed requests from
 * DemoServiceRequestSeeder and creates one review per request.
 *
 * To make the totals interesting, we also create reviews for a subset
 * of completed requests across the general pool (not just the demo
 * ones), which gives more data for review-count aggregation.
 */
class DemoReviewSeeder extends Seeder
{
    private const COMMENTS = [
        5 => [
            'Excellent work, arrived on time and finished quickly.',
            'Very professional and clean. Would hire again.',
            'Great job — explained everything clearly and charged fairly.',
            'Highly recommend. Solved the problem in one visit.',
            'Fantastic service. Knew exactly what to do.',
        ],
        4 => [
            'Good work overall. Minor delay but the result was solid.',
            'Skilled and courteous. Slightly pricey but worth it.',
            'Solid job. Would use again for similar work.',
            'Professional and efficient. Communication could be better.',
        ],
        3 => [
            'Work was done but took longer than expected.',
            'Acceptable result, but not the cleanest finish.',
            'Fine for the price, though scheduling was tricky.',
        ],
    ];

    public function run(): void
    {
        // Find all completed requests without a review yet. Cap at 30
        // so the seeder stays fast even in a large database.
        $completedRequests = ServiceRequest::where('status', 'completed')
            ->limit(30)
            ->get();

        if ($completedRequests->isEmpty()) {
            $this->command->warn('No completed requests — skipping review seeding.');
            return;
        }

        $count = 0;

        foreach ($completedRequests as $request) {
            // Skip if a review already exists for this request.
            $existing = Review::where('service_request_id', (string) $request->_id)->first();
            if ($existing) {
                continue;
            }

            // Deterministic rating based on request id hash.
            // Reviews skew positive for demo realism.
            $hash = crc32((string) $request->_id);
            $mod = $hash % 10;
            $rating = match (true) {
                $mod < 6 => 5,
                $mod < 9 => 4,
                default => 3,
            };

            Review::create([
                'service_request_id' => (string) $request->_id,
                'customer_id' => (string) $request->customer_id,
                'artisan_id' => (string) ($request->selected_artisan_id ?? ''),
                'rating' => $rating,
                'comment' => self::COMMENTS[$rating][array_rand(self::COMMENTS[$rating])],
            ]);

            $count++;
        }

        $this->command->info("Seeded {$count} demo reviews on completed requests.");
    }
}