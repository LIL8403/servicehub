<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::table('service_requests', function (Blueprint $collection) {
            $collection->index(['status' => 1, 'pending_since' => 1], 'service_requests_pending_response_expiry_index');
        });
    }

    public function down(): void
    {
        Schema::table('service_requests', function (Blueprint $collection) {
            $collection->dropIndexIfExists('service_requests_pending_response_expiry_index');
        });
    }
};
