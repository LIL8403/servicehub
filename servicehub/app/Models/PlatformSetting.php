<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

class PlatformSetting extends Model
{
    use HasFactory;

    protected $fillable = ['key', 'value', 'description', 'updated_by'];

    protected function casts(): array
    {
        return ['value' => 'float'];
    }
}
