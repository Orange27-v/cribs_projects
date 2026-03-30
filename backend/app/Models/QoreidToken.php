<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class QoreidToken extends Model
{
    protected $fillable = [
        'access_token',
        'expires_at',
        'last_used_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'last_used_at' => 'datetime',
    ];

    /**
     * Check if the token has expired.
     *
     * @return bool
     */
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Mark the token as used by updating last_used_at timestamp.
     *
     * @return void
     */
    public function markAsUsed(): void
    {
        $this->update(['last_used_at' => now()]);
    }
}
