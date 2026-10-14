<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('service_requests', function (Blueprint $collection) {
            $collection->index(['customer_id' => 1, 'created_at' => -1], 'service_requests_customer_created_index');
            $collection->index(['selected_artisan_id' => 1, 'status' => 1], 'service_requests_artisan_status_index');
            $collection->index(['service_id' => 1, 'status' => 1], 'service_requests_service_status_index');
            $collection->geospatial('location', '2dsphere', ['name' => 'service_requests_location_2dsphere']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_requests');
    }
};
