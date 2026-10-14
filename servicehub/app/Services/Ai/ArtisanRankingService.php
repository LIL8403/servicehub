<?php

namespace App\Services\Ai;

use App\Ai\Agents\ArtisanRecommender;
use App\Models\ServiceRequest;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;
use Laravel\Ai\Responses\StructuredAgentResponse;
use UnexpectedValueException;

class ArtisanRankingService
{
    /**
     * Return a sanitized, advisory AI ranking for already eligible artisans.
     *
     * @return array<int, array{artisan_id: string, match_score: int, reason: string}>
     */
    public function rankArtisans(ServiceRequest $request, Collection $eligibleArtisans): array
    {
        if ($eligibleArtisans->isEmpty() || ! $this->isAvailable()) {
            return [];
        }

        $candidates = $eligibleArtisans
        ->take(10)
        ->map(fn($artisan) => [
            'id' => (string) $artisan->getKey(),
            'professional_title' => $artisan->professional_title,
            'experience_years' => (int) ($artisan->experience_years ?? 0),
            'rating_average' => (float) ($artisan->rating_average ?? 0),
            'completed_jobs' => (int) ($artisan->completed_jobs ?? 0),
            'service_areas' => $artisan->service_areas ?? [],
        ])->values();
        $eligibleIds = $candidates->pluck('id')->flip();

        try {
            $response = ArtisanRecommender::make()->prompt(json_encode([
                'request' => [
                    'description' => $request->description,
                    'location_label' => data_get($request->location, 'label'),
                    'preferred_schedule' => $request->preferred_schedule,
                ],
                'eligible_artisans' => $candidates->all(),
                'output_requirement' => 'Return only the supplied artisan IDs. Rank at most three. Keep each reason to 120 characters or fewer.',
            ], JSON_THROW_ON_ERROR), timeout: 5);

            if (! $response instanceof StructuredAgentResponse) {
                throw new UnexpectedValueException('The AI ranking agent did not return structured output.');
            }

            $result = $response->toArray();

            Log::info('ai.raw_response', [
                'service_request_id' => $request->getKey(),
                'result' => $result,
            ]);

            $sanitized = collect($result['recommendations'] ?? [])
                ->filter(fn($item) => is_array($item)
                    && isset($item['artisan_id'], $item['confidence_score'], $item['reason'])
                    && $eligibleIds->has((string) $item['artisan_id'])
                    && is_numeric($item['confidence_score'])
                    && (float) $item['confidence_score'] >= 0
                    && (float) $item['confidence_score'] <= 100
                    && is_string($item['reason']))
                ->map(fn(array $item) => [
                    'artisan_id' => (string) $item['artisan_id'],
                    'match_score' => (int) round((float) $item['confidence_score']),
                    'reason' => mb_substr(trim($item['reason']), 0, 120),
                ])
                ->sortByDesc('match_score')
                ->take(3)
                ->values()
                ->all();

            Log::info('ai.sanitized', [
                'service_request_id' => $request->getKey(),
                'input_count' => count($result['recommendations'] ?? []),
                'output_count' => count($sanitized),
            ]);

            return $sanitized;
        } catch (\Throwable $exception) {
            Log::warning('ai.artisan_ranking_failed', [
                'service_request_id' => $request->getKey(),
                'exception' => $exception::class,
                'message' => $exception->getMessage(),
                'previous' => $exception->getPrevious()?->getMessage(),
                'previous_class' => $exception->getPrevious() ? get_class($exception->getPrevious()) : null,
            ]);

            return [];
        }
    }

    public function isAvailable(): bool
    {
        $provider = config('ai.default');

        return is_string($provider) && filled(config("ai.providers.{$provider}.key"));
    }
}
