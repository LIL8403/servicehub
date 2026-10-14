<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::table('service_requests', function (Blueprint $collection) {
            $collection->index('payment_id', 'service_requests_payment_index', null, ['sparse' => true]);
        });
    }

    public function down(): void
    {
        Schema::table('service_requests', function (Blueprint $collection) {
            $collection->dropIndex('service_requests_payment_index');
        });
    }
};
