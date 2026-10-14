<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    protected $fillable = [
        'service_request_id',
        'customer_id',
        'artisan_profile_id',
        'rating',
        'comment',
        'tags',
        'created_at',
        'updated_at',
    ];

    protected function casts(): array
    {
        return [
            'rating' => 'integer',
            'tags' => 'array',
        ];
    }
}