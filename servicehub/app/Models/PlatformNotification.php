<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

class PlatformNotification extends Model
{
    use HasFactory;

    protected $fillable = ['recipient_id', 'type', 'title', 'body', 'payload', 'read_at'];

    protected function casts(): array
    {
        return ['read_at' => 'datetime'];
    }
}
