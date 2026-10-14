<?php

namespace App\Enums;

enum DisputeStatus: string
{
    case OPENED = 'opened';
    case UNDER_REVIEW = 'under_review';
    case AWAITING_INFORMATION = 'awaiting_information';
    case PENDING_EXECUTION = 'pending_execution';
    case UNDER_INVESTIGATION = 'under_investigation';
    case RESOLVED_WITH_MANUAL_REFUND_PENDING = 'resolved_with_manual_refund_pending';
    case RECONCILIATION_REQUIRED = 'reconciliation_required';
    case RESOLVED = 'resolved';
    case CLOSED = 'closed';
}
