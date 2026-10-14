<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('disputes', function (Blueprint $collection) {
            $collection->index(['service_request_id' => 1, 'created_at' => -1], 'disputes_request_created_index');
            $collection->index(['reporter_id' => 1, 'created_at' => -1], 'disputes_reporter_created_index');
            $collection->index(['status' => 1, 'created_at' => -1], 'disputes_status_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('disputes');
    }
};
