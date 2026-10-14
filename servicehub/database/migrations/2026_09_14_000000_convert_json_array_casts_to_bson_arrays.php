<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        $database = DB::connection('mongodb')->getMongoDB();

        $this->convert($database->selectCollection('users'), ['roles']);
        $this->convert($database->selectCollection('audit_logs'), ['metadata']);
        $this->convert($database->selectCollection('platform_notifications'), ['payload']);
    }

    public function down(): void {}

    private function convert($collection, array $fields): void
    {
        foreach ($collection->find() as $document) {
            $updates = [];

            foreach ($fields as $field) {
                $value = $document[$field] ?? null;

                if (is_string($value) && json_validate($value)) {
                    $updates[$field] = json_decode($value, true, flags: JSON_THROW_ON_ERROR);
                }
            }

            if ($updates !== []) {
                $collection->updateOne(['_id' => $document['_id']], ['$set' => $updates]);
            }
        }
    }
};
