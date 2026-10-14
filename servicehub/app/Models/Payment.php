<?php

namespace App\Models;

use App\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $hidden = [
        'phone',
        'events',
    ];

    protected $fillable = [
        'service_request_id', 'customer_id', 'amount', 'currency', 'status', 'provider','provider_channel',
        'provider_reference', 'idempotency_key', 'external_reference', 'phone', 'events', 'ai_anomaly',
        'commission_rate_snapshot', 'commission_amount', 'artisan_gross_amount', 'artisan_net_amount',
    ];

    protected function casts(): array
    {
        return [
            'status' => PaymentStatus::class,
            'commission_rate_snapshot' => 'float',
            'commission_amount' => 'float',
            'artisan_gross_amount' => 'float',
            'artisan_net_amount' => 'float',
        ];
    }
}
