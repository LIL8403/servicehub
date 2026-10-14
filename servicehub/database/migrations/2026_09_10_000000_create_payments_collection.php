<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('payments', function (Blueprint $collection) {
            $collection->unique(['customer_id' => 1, 'idempotency_key' => 1], 'payments_customer_idempotency_unique');
            $collection->unique('provider_reference', 'payments_provider_reference_unique', null, ['sparse' => true]);
            $collection->index(['service_request_id' => 1, 'created_at' => -1], 'payments_request_created_index');
            $collection->index(['status' => 1, 'created_at' => -1], 'payments_status_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
