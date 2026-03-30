<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Inspection extends Model
{
    use HasFactory;

    protected $table = 'inspections';

    protected $fillable = [
        'user_id',
        'agent_id',
        'property_id',
        'transaction_id',
        'inspection_date',
        'inspection_time',
        'status',
        'reason_cancellation',
        'reschedule_date',
        'reschedule_time',
        'amount',
        'payment_status',
        'payment_method',
    ];

    protected $casts = [
        'inspection_date' => 'date',
        'inspection_time' => 'string', // Cast to string to handle H:i format
        'reschedule_date' => 'date',
        'reschedule_time' => 'string', // Cast to string to handle H:i format
        'amount' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function agent()
    {
        // Fixed: agent_id in inspections → agent_id in cribs_agents (not id)
        return $this->belongsTo(Agent::class, 'agent_id', 'agent_id');
    }

    public function property()
    {
        return $this->belongsTo(Property::class);
    }

    public function transaction()
    {
        return $this->belongsTo(Transaction::class);
    }
}