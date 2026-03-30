<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'user_type',
        'push_notifications_enabled',
        'new_messages_enabled',
        'new_listings_enabled',
        'price_changes_enabled',
        'app_updates_enabled',
    ];

    protected $casts = [
        'push_notifications_enabled' => 'boolean',
        'new_messages_enabled' => 'boolean',
        'new_listings_enabled' => 'boolean',
        'price_changes_enabled' => 'boolean',
        'app_updates_enabled' => 'boolean',
    ];

    /**
     * Get the parent user or agent model.
     */
    public function user()
    {
        return $this->morphTo('user', 'user_type', 'user_id');
    }
}
