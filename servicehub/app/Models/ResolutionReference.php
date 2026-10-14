<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

/**
 * A durable, globally unique idempotency ledger for financial dispute actions.
 */
class ResolutionReference extends Model
{
    use HasFactory;

    protected $fillable = ['reference', 'dispute_id', 'status'];
}
