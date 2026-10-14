<?php

namespace App\Models;

use App\Enums\ServiceRequestStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use MongoDB\Laravel\Eloquent\Model;
use App\Enums\UrgencyLevel;

class ServiceRequest extends Model
{
    use HasFactory;

    protected $hidden = [
        'images',
    ];

    protected $appends = [
        'image_attachments',
    ];

    protected $fillable = [
        'customer_id', 'service_id', 'description', 'location', 'images', 'formatted_address', 'preferred_schedule',
        'status', 'selected_artisan_id', 'payment_id', 'status_history', 'inspection', 'quotation',
        'materials', 'completion', 'recommendation', 'pending_since', 'no_artisan_reason', 'matching_attempts',
        'selection_history', 'ai_assist_enabled', 'urgency', 'cancellation',
    ];

    protected $attributes = [
        'matching_attempts' => 0,
        'selection_history' => [],
        'ai_assist_enabled' => false,
    ];

    protected function casts(): array
    {
        return [
            'status' => ServiceRequestStatus::class,
            'pending_since' => 'datetime',
            'matching_attempts' => 'integer',
            'ai_assist_enabled' => 'boolean',
            'urgency' => UrgencyLevel::class
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function service(): BelongsTo
    {
        return $this->belongsTo(Service::class);
    }

    public function selectedArtisan(): BelongsTo
    {
        return $this->belongsTo(Artisan::class, 'selected_artisan_id');
    }

    public function getImageAttachmentsAttribute(): array
    {
        return collect($this->images ?? [])->map(fn (array $image) => [
            'id' => $image['id'],
            'name' => $image['name'],
            'mime_type' => $image['mime_type'],
            'size' => $image['size'],
        ])->values()->all();
    }
}
