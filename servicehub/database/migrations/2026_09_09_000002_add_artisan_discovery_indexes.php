<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::table('artisan_profiles', function (Blueprint $collection) {
            $collection->index(['verification_status' => 1, 'service_offerings.service_reference' => 1], 'artisan_profiles_discovery_service_index');
            $collection->geospatial('service_location', '2dsphere', ['name' => 'artisan_profiles_service_location_2dsphere']);
        });
    }

    public function down(): void
    {
        Schema::table('artisan_profiles', function (Blueprint $collection) {
            $collection->dropIndexIfExists('artisan_profiles_discovery_service_index');
            $collection->dropIndexIfExists('artisan_profiles_service_location_2dsphere');
        });
    }
};
