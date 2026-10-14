<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('artisan_profiles', function (Blueprint $collection) {
            $collection->unique('user_id', 'artisan_profiles_user_id_unique');
            $collection->index(['verification_status' => 1], 'artisan_profiles_verification_status_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('artisan_profiles');
    }
};
