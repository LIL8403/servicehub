<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;
use MongoDB\Laravel\Schema\Blueprint;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        Schema::create('payouts', function (Blueprint $collection) {
            $collection->unique('payment_id', 'payouts_payment_unique');
            $collection->unique('provider_reference', 'payouts_provider_reference_unique', null, ['sparse' => true]);
            $collection->index(['artisan_profile_id' => 1, 'created_at' => -1], 'payouts_artisan_created_index');
            $collection->index(['status' => 1, 'created_at' => -1], 'payouts_status_created_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payouts');
    }
};
