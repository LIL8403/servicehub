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
        Schema::table('disputes', function (Blueprint $collection) {
            $collection->index(['status' => 1, 'pending_resolution.expires_at' => 1], 'disputes_pending_resolution_expiry_index');
        });

        $database = DB::connection('mongodb')->getMongoDB();
        // Previous versions used payment-level dispute states. A dispute now
        // controls release blocking while its eligible payment remains held.
        // Existing payments intentionally receive no commission snapshot: doing
        // so would apply a later rate retroactively.
        $database->selectCollection('payments')->updateMany(
            ['status' => ['$in' => ['disputed', 'under_review']]],
            ['$set' => ['status' => 'held']],
        );
    }

    public function down(): void
    {
        Schema::table('disputes', fn (Blueprint $collection) => $collection->dropIndex('disputes_pending_resolution_expiry_index'));
    }
};
