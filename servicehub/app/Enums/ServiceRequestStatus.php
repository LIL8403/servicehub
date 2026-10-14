<?php

namespace App\Enums;

enum ServiceRequestStatus: string
{
    case CREATED = 'created';
    case AWAITING_ARTISAN_SELECTION = 'awaiting_artisan_selection';
    case PENDING_ARTISAN_RESPONSE = 'pending_artisan_response';
    case ARTISAN_APPROVED = 'artisan_approved';
    case ARTISAN_SELECTED = 'artisan_selected';
    case NO_ARTISAN_AVAILABLE = 'no_artisan_available';
    case INSPECTION_SCHEDULED = 'inspection_scheduled';
    case INSPECTION_COMPLETED = 'inspection_completed';
    case QUOTATION_PENDING = 'quotation_pending';
    case QUOTATION_RECEIVED = 'quotation_received';
    case QUOTATION_ACCEPTED = 'quotation_accepted';
    case PAYMENT_PENDING = 'payment_pending';
    case BOOKED = 'booked';
    case IN_PROGRESS = 'in_progress';
    case AWAITING_CONFIRMATION = 'awaiting_confirmation';
    case COMPLETED = 'completed';
    case CANCELLED = 'cancelled';
    case DISPUTED = 'disputed';
}
