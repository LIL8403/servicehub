<?php

namespace App\Models;

use App\Enums\DisputeStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

class Dispute extends Model
{
    use HasFactory;

    protected $fillable = [
        'service_request_id', 'payment_id', 'reporter_id', 'reporter_role', 'reason', 'description',
        'urgency','evidence', 'updates', 'status', 'prior_request_status', 'status_history', 'resolution',
        'pending_resolution', 'resolution_reference',
    ];

    protected function casts(): array
    {
        return ['status' => DisputeStatus::class];
    }
}
