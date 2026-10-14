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
        Schema::create('customers', function (Blueprint $collection) {
            $collection->unique('user_id', 'customers_user_id_unique');
        });

        Schema::create('artisans', function (Blueprint $collection) {
            $collection->unique('user_id', 'artisans_user_id_unique');
            $collection->index('verification_status', 'artisans_verification_status_index');
            $collection->index(['location' => '2dsphere'], 'artisans_location_2dsphere');
            $collection->index(['verification_status' => 1, 'service_offerings.service_reference' => 1], 'artisans_discovery_service_index');
        });

        Schema::create('administrators', function (Blueprint $collection) {
            $collection->unique('user_id', 'administrators_user_id_unique');
        });

        $database = DB::connection('mongodb')->getMongoDB();
        $users = $database->selectCollection('users');
        $customers = $database->selectCollection('customers');
        $artisans = $database->selectCollection('artisans');
        $administrators = $database->selectCollection('administrators');

        foreach ($users->find() as $user) {
            $roles = $this->array($user['roles'] ?? []);
            if (in_array('artisan', $roles, true) && ! in_array('admin', $roles, true)) {
                $roles = array_values(array_unique([...$roles, 'customer']));
            }
            $name = trim((string) ($user['name'] ?? ''));
            [$firstName, $lastName] = array_pad(preg_split('/\s+/', $name, 2, PREG_SPLIT_NO_EMPTY) ?: [], 2, null);

            $users->updateOne(['_id' => $user['_id']], ['$set' => [
                'first_name' => $user['first_name'] ?? $firstName,
                'last_name' => $user['last_name'] ?? $lastName,
                'account_status' => $user['account_status'] ?? $user['status'] ?? 'active',
                'active_role' => $user['active_role'] ?? ($roles[0] ?? null),
                'roles' => $roles,
            ]]);

            if (in_array('customer', $roles, true)) {
                $profile = $this->array($user['customer_profile'] ?? []);
                $customers->updateOne(['user_id' => (string) $user['_id']], ['$setOnInsert' => [
                    'user_id' => (string) $user['_id'],
                    'preferences' => $this->array($profile['preferences'] ?? []),
                    'favorite_artisans' => [],
                    'address_book' => isset($profile['default_location']) ? [$profile['default_location']] : [],
                    'total_spent' => 0,
                    'total_requests' => 0,
                    'completed_requests' => 0,
                ]], ['upsert' => true]);
            }

            if (in_array('admin', $roles, true)) {
                $administrators->updateOne(['user_id' => (string) $user['_id']], ['$setOnInsert' => [
                    'user_id' => (string) $user['_id'], 'role_level' => 'administrator', 'permissions' => [],
                ]], ['upsert' => true]);
            }
        }

        foreach ($database->selectCollection('artisan_profiles')->find() as $profile) {
            $data = $profile->getArrayCopy();
            unset($data['_id']);
            $data['professional_description'] ??= $data['bio'] ?? $data['professional_title'] ?? null;
            $data['offered_services'] ??= $this->array($data['service_offerings'] ?? []);
            $data['location'] ??= $data['service_location'] ?? null;
            $data['certifications'] ??= [];
            $data['languages'] ??= [];
            $data['verification_documents'] ??= [];
            $data['payout_account'] ??= $data['payout_phone'] ?? null;
            $data['completed_jobs'] ??= 0;
            $data['response_rate'] ??= 0;
            $data['cancellation_rate'] ??= 0;
            $artisans->updateOne(['user_id' => (string) $profile['user_id']], ['$setOnInsert' => $data], ['upsert' => true]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('administrators');
        Schema::dropIfExists('artisans');
        Schema::dropIfExists('customers');
    }

    private function array(mixed $value): array
    {
        if (is_object($value) && method_exists($value, 'getArrayCopy')) {
            return $value->getArrayCopy();
        }

        return is_array($value) ? $value : [];
    }
};
