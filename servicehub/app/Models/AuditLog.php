<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use LogicException;
use MongoDB\Laravel\Eloquent\Model;

class AuditLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'event_type', 'actor_id', 'subject_type', 'subject_id', 'metadata', 'expires_at',
    ];

    protected function casts(): array
    {
        return ['expires_at' => 'datetime'];
    }

    protected static function booted(): void
    {
        static::updating(fn () => throw new LogicException('Audit logs are immutable.'));
        static::deleting(fn () => throw new LogicException('Audit logs are immutable.'));
    }
}
