<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        $database = DB::connection('mongodb')->getMongoDB();

        $this->ensureIndexes($database->selectCollection('users'), [
            [['email' => 1], ['name' => 'users_email_unique', 'unique' => true]],
            [['phone' => 1], [
                'name' => 'users_phone_unique',
                'unique' => true,
                'partialFilterExpression' => ['phone' => ['$type' => 'string']],
            ]],
            [['status' => 1], ['name' => 'users_status_index']],
        ]);
        $this->ensureIndexes($database->selectCollection('artisan_profiles'), [
            [['user_id' => 1], ['name' => 'artisan_profiles_user_id_unique', 'unique' => true]],
            [['verification_status' => 1, 'service_offerings.service_reference' => 1], ['name' => 'artisan_profiles_discovery_service_index']],
            [['service_location' => '2dsphere'], ['name' => 'artisan_profiles_service_location_2dsphere']],
        ]);
        $this->ensureIndexes($database->selectCollection('service_requests'), [
            [['customer_id' => 1, 'created_at' => -1], ['name' => 'service_requests_customer_created_index']],
            [['selected_artisan_id' => 1, 'status' => 1], ['name' => 'service_requests_artisan_status_index']],
            [['service_id' => 1, 'status' => 1], ['name' => 'service_requests_service_status_index']],
            [['location' => '2dsphere'], ['name' => 'service_requests_location_2dsphere']],
        ]);
    }

    public function down(): void {}

    private function ensureIndexes($collection, array $indexes): void
    {
        $existing = iterator_to_array($collection->listIndexes());

        foreach ($indexes as [$keys, $options]) {
            $exists = collect($existing)->contains(function ($index) use ($keys, $options) {
                return $index->getName() === $options['name'] || $index->getKey() == $keys;
            });

            if (! $exists) {
                $collection->createIndex($keys, $options);
            }
        }
    }
};
