<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('users', function (Blueprint $collection) {
            $collection->unique('email', 'users_email_unique');
            $collection->index(['status' => 1], 'users_status_index');
        });

        DB::connection('mongodb')
            ->getMongoDB()
            ->selectCollection('users')
            ->createIndex(
                ['phone' => 1],
                [
                    'unique' => true,
                    'partialFilterExpression' => ['phone' => ['$type' => 'string']],
                    'name' => 'users_phone_unique',
                ],
            );

        Schema::create('password_reset_tokens', function (Blueprint $collection) {
            $collection->unique('email', 'password_reset_tokens_email_unique');
            $collection->expire('created_at', 3600);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
