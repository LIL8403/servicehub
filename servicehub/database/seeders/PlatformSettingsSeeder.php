<?php

namespace Database\Seeders;

use App\Models\PlatformSetting;
use Illuminate\Database\Seeder;

class PlatformSettingsSeeder extends Seeder
{
    public function run(): void
    {
        PlatformSetting::query()->firstOrCreate(
            ['key' => 'artisan_response_timeout_hours'],
            ['value' => 24, 'description' => 'Number of hours before a pending artisan response expires'],
        );
    }
}
