<?php

namespace App\Enums;

enum PayoutStatus: string
{
    case INITIATED = 'initiated';
    case PROCESSING = 'processing';
    case PAID = 'paid';
    case FAILED = 'failed';
}
