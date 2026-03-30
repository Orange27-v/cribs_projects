<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $table = 'transactions';

    protected $fillable = [
        'payer_id',
        'payee_id',
        'amount',
        'currency',
        'payment_reference',
        'gateway',
        'channel',
        'status',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
    ];

    public function payer()
    {
        return $this->belongsTo(User::class, 'payer_id');
    }

    public function payee()
    {
        return $this->belongsTo(Agent::class, 'payee_id');
    }
}