<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AgentPlan extends Model
{
    use HasFactory;

    protected $table = 'agent_plans';
    protected $primaryKey = 'plan_id';

    protected $fillable = [
        'name',
        'property_limit',
        'price',
        'description',
        'features',
    ];

    protected $casts = [
        'features' => 'array',
        'price' => 'decimal:2',
    ];
}
