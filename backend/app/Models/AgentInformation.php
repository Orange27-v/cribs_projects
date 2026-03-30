<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AgentInformation extends Model
{
    use HasFactory;

    protected $table = 'agent_information';

    protected $fillable = [
        'agent_id',
        'booking_fees',
        'bio',
        'gender',
        'is_licensed',
        'agent_rank',
        'experience_years',
        'profile_picture_url',
        'member_since',
        'average_response_time_minutes',
        'total_sales',
        'average_rating',
        'total_reviews',
        'active_areas',
    ];

    protected $casts = [
        'is_licensed' => 'boolean',
        'member_since' => 'datetime',
        'active_areas' => 'array',
        'average_rating' => 'float',
    ];

    public function agent()
    {
        return $this->belongsTo(Agent::class, 'agent_id', 'agent_id');
    }
}