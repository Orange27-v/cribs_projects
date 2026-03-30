<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeviceToken extends Model
{
    use HasFactory;

    protected $fillable = [
        'tokenable_id',
        'tokenable_type',
        'platform',
        'fcm_token',
        'last_seen_at',
    ];

    protected $casts = [
        'last_seen_at' => 'datetime',
    ];

    /**
     * Get the parent tokenable model (user or agent).
     */
    public function tokenable()
    {
        return $this->morphTo();
    }
}
