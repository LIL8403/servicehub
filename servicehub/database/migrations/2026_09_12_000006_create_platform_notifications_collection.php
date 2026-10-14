<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('platform_notifications', function (Blueprint $collection) {
            $collection->index(['recipient_id' => 1, 'created_at' => -1], 'platform_notifications_recipient_created_index');
            $collection->index(['recipient_id' => 1, 'read_at' => 1], 'platform_notifications_recipient_read_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_notifications');
    }
};
