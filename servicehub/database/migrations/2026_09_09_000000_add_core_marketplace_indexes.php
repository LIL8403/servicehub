<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    protected $connection = 'mongodb';

    public function up(): void
    {
        // Indexes are established when the collections are created.
    }

    public function down(): void
    {
        // Collection lifecycle migrations own these indexes.
    }
};
