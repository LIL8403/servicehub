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
        Schema::create('personal_access_tokens', function (Blueprint $collection) {
            $collection->unique('token', 'personal_access_tokens_token_unique');
            $collection->index(['tokenable_type' => 1, 'tokenable_id' => 1], 'personal_access_tokens_tokenable_index');
            $collection->index(['expires_at' => 1], 'personal_access_tokens_expires_at_index');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
    }
};
