<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Verification extends Model
{
    use HasFactory;

    protected $fillable = [
        'receiver_id',
        'receiver_type',
        'type',
        'value',
        'status',
        'verification_id',
        'qoreid_reference',
        'response_payload',
    ];

    protected $casts = [
        'response_payload' => 'array',
    ];
}
