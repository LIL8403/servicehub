<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('platform_settings', function (Blueprint $collection) {
            $collection->unique('key', 'platform_settings_key_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_settings');
    }
};
