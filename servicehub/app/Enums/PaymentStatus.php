<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case INITIATED = 'initiated';
    case PROCESSING = 'processing';
    case HELD = 'held';
    case FAILED = 'failed';
    case CANCELLED = 'cancelled';
    case RELEASING = 'releasing';
    case RELEASED = 'released';
    case REFUNDING = 'refunding';
    case REFUNDED = 'refunded';
    case PARTIALLY_REFUNDED = 'partially_refunded';
    case REFUND_PENDING_MANUAL = 'refund_pending_manual';
    case RECONCILIATION_REQUIRED = 'reconciliation_required';
    case DISPUTED = 'disputed';
    case UNDER_REVIEW = 'under_review';
}
