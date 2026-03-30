<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    use HasFactory;

    protected $table = 'inspections'; // Map to the inspections table

    protected $fillable = [
        'user_id',
        'agent_id',
        'property_id',
        'transaction_id',
        'inspection_date',
        'inspection_time',
        'status',
        'reason_cancellation',
        'amount',
        'payment_status',
        'payment_method',
    ];

    protected $casts = [
        'inspection_date' => 'date',
        'inspection_time' => 'datetime', // Cast to datetime to easily access time components
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function agent()
    {
        return $this->belongsTo(Agent::class, 'agent_id', 'agent_id');
    }

    public function property()
    {
        return $this->belongsTo(Property::class, 'property_id');
    }

    public function transaction()
    {
        return $this->belongsTo(Transaction::class, 'transaction_id');
    }
}
