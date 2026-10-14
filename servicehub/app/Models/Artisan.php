<?php

namespace App\Models;

use App\Enums\VerificationStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use MongoDB\Laravel\Eloquent\Model;

class Artisan extends Model
{
    use HasFactory;

    protected $table = 'artisans';

    protected $hidden = ['payout_account', 'verification_documents'];

    protected $fillable = [
        'user_id',
        'professional_description',
        'professional_title',
        'bio',
        'experience_years',
        'certifications',
        'languages',
        'service_areas',
        'service_location',
        'availability',
        'location',
        'offered_services',
        'service_offerings',
        'verification_status',
        'verification_documents',
        'verification_history',
        'rejection_reason',
        'reviewed_at',
        'payout_account',
        'payout_phone',
        'rating_average',
        'review_count',
        'completed_jobs',
        'response_rate',
        'cancellation_rate',
        'legal_name',
        'date_of_birth',
        'residential_address',
        'identity_document',
        'verification_selfie',
        'verification_documents',
        'verification_submitted_at',
        'verification_rejection_reason',
    ];

    protected $attributes = [
        'certifications' => [],
        'languages' => [],
        'service_areas' => [],
        'offered_services' => [],
        'service_offerings' => [],
        'availability' => [],
        'verification_documents' => [],
        'verification_history' => [],
        'rating_average' => 0,
        'review_count' => 0,
        'completed_jobs' => 0,
        'response_rate' => 0,
        'cancellation_rate' => 0,
    ];

    protected function casts(): array
    {
        return [
            'verification_status' => VerificationStatus::class,
            'reviewed_at' => 'datetime',
            'date_of_birth' => 'date',
            'verification_submitted_at' => 'datetime',
            'identity_document' => 'array',
            'verification_selfie' => 'array',
            'verification_documents' => 'array',
            'verification_history' => 'array',
            'service_areas' => 'array',
            'availability' => 'array',
            'languages' => 'array',
            'certifications' => 'array',
            'service_offerings' => 'array',
            'location' => 'array',
            'service_location' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isProfileComplete(): bool
    {
        return filled($this->professional_description ?? $this->bio ?? $this->professional_title)
            && $this->experience_years !== null;
    }

    public function setServiceLocationAttribute(?array $location): void
    {
        $this->attributes['service_location'] = $location;
        $this->attributes['location'] = $location;
    }
}
