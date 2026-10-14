<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('messages', function (Blueprint $collection) {
            $collection->index(['conversation_id' => 1, 'created_at' => 1], 'messages_conversation_created_index');
            $collection->index(['sender_id' => 1, 'created_at' => -1], 'messages_sender_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
