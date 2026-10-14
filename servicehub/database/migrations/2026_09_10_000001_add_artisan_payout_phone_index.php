<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::table('artisan_profiles', function (Blueprint $collection) {
            $collection->sparse('payout_phone', ['name' => 'artisan_profiles_payout_phone_sparse_index']);
        });
    }

    public function down(): void
    {
        Schema::table('artisan_profiles', function (Blueprint $collection) {
            $collection->dropIndexIfExists('artisan_profiles_payout_phone_sparse_index');
        });
    }
};
