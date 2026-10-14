<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('resolution_references', function (Blueprint $collection) {
            $collection->unique('reference', 'resolution_references_reference_unique');
            $collection->index(['dispute_id' => 1, 'created_at' => -1], 'resolution_references_dispute_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('resolution_references');
    }
};
