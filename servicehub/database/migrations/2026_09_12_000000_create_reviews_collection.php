<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $collection) {
            $collection->unique('service_request_id', 'reviews_service_request_unique');
            $collection->index(['artisan_profile_id' => 1, 'created_at' => -1], 'reviews_artisan_created_index');
            $collection->index(['customer_id' => 1, 'created_at' => -1], 'reviews_customer_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
