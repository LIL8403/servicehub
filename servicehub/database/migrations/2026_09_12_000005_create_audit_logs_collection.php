<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $collection) {
            $collection->index(['subject_type' => 1, 'subject_id' => 1, 'created_at' => -1], 'audit_logs_subject_created_index');
            $collection->index(['actor_id' => 1, 'created_at' => -1], 'audit_logs_actor_created_index');
            $collection->index('expires_at', 'audit_logs_retention_ttl', null, ['expireAfterSeconds' => 0]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};
