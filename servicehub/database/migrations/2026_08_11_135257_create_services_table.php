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
        Schema::create('services', function (Blueprint $collection) {
            $collection->unique('slug', 'services_slug_unique');
            $collection->unique(['service_category_id' => 1, 'name' => 1], 'services_category_name_unique');
            $collection->index(['is_active' => 1, 'service_category_id' => 1, 'name' => 1], 'services_active_category_name_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('services');
    }
};
