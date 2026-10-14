<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $collection) {
            $collection->unique('service_request_id', 'conversations_service_request_unique');
            $collection->index(['customer_id' => 1, 'updated_at' => -1], 'conversations_customer_updated_index');
            $collection->index(['artisan_profile_id' => 1, 'updated_at' => -1], 'conversations_artisan_updated_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};
