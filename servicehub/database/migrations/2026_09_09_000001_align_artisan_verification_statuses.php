<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        DB::connection('mongodb')->getMongoDB()->selectCollection('artisan_profiles')->updateMany(
            ['verification_status' => 'approved'],
            ['$set' => ['verification_status' => 'verified']],
        );
    }

    public function down(): void
    {
        DB::connection('mongodb')->getMongoDB()->selectCollection('artisan_profiles')->updateMany(
            ['verification_status' => 'verified'],
            ['$set' => ['verification_status' => 'approved']],
        );
    }
};
