<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use MongoDB\Laravel\Eloquent\Model;

class Administrator extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'role_level', 'permissions'];

    protected $attributes = ['role_level' => 'administrator', 'permissions' => []];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
