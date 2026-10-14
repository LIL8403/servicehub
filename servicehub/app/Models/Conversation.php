<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use MongoDB\Laravel\Eloquent\Model;

class Conversation extends Model
{
    use HasFactory;

    protected $fillable = ['service_request_id', 'customer_id', 'artisan_profile_id'];
}
