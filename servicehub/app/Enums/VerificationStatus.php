<?php

namespace App\Enums;

enum VerificationStatus: string
{
    case UNVERIFIED = 'unverified';
    case PENDING = 'pending';
    case VERIFIED = 'verified';
    case REJECTED = 'rejected';
    case SUSPENDED = 'suspended';
}
