<?php

namespace App\Models;

use App\Enums\PayoutStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

class Payout extends Model
{
    use HasFactory;

    protected $hidden = [
        'events',
    ];

    protected $fillable = [
        'payment_id', 'service_request_id', 'artisan_profile_id', 'amount', 'currency',
        'status', 'provider', 'provider_reference', 'external_reference', 'events',
        'gross_amount', 'commission_amount',
    ];

    protected function casts(): array
    {
        return ['status' => PayoutStatus::class];
    }
}
