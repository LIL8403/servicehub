<?php

use App\Models\Artisan;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Log;

/**
 * Converts `artisans.service_areas` from the legacy shape
 * (`[{city, radius_km}, ...]`) to a flat list of city names
 * (`["Douala", "Yaoundé"]`).
 *
 * Radius is a concept artisans don't reason about. It's dropped here
 * and replaced by the single `availability.radius_km` field, which is
 * the artisan's overall reach.
 */
return new class extends Migration
{
    public function up(): void
    {
        $migrated = 0;

        Artisan::query()->chunk(100, function ($artisans) use (&$migrated) {
            foreach ($artisans as $artisan) {
                $areas = $artisan->service_areas ?? [];

                // Already flat? Skip.
                if ($this->isFlat($areas)) {
                    continue;
                }

                $cities = collect($areas)
                    ->filter(fn ($a) => is_array($a) && ! empty($a['city']))
                    ->pluck('city')
                    ->unique()
                    ->values()
                    ->all();

                $artisan->update(['service_areas' => $cities]);
                $migrated++;
            }
        });

        Log::info("Migration: normalized service_areas on {$migrated} artisan(s).");
    }

    public function down(): void
    {
        // No-op. Reverting would lose the radius values we never
        // preserved, so we keep the flat shape on rollback.
    }

    private function isFlat(array $areas): bool
    {
        foreach ($areas as $entry) {
            if (is_array($entry)) return false;
            if (! is_string($entry)) return false;
        }
        return true;
    }
};