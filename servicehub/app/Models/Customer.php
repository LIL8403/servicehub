<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use MongoDB\Laravel\Eloquent\Model;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'preferences', 'favorite_artisans', 'address_book',
        'total_spent', 'total_requests', 'completed_requests',
    ];

    protected $attributes = [
        'preferences' => [],
        'favorite_artisans' => [],
        'address_book' => [],
        'total_spent' => 0,
        'total_requests' => 0,
        'completed_requests' => 0,
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
