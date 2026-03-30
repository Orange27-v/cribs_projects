<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable; // Change to Authenticatable
use Illuminate\Notifications\Notifiable; // Add Notifiable

use Laravel\Sanctum\HasApiTokens; // Add HasApiTokens

class Agent extends Authenticatable // Change to Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens; // Add HasApiTokens

    protected $table = 'cribs_agents';

    protected $fillable = [
        'agent_id',
        'first_name',
        'last_name',
        'email',
        'phone',
        'email_verified_at',
        'password',
        'area',
        'role',
        'latitude',
        'longitude',
        'login_status',
        'last_login',
        'last_logout',
        'remember_token',
        'email_verification_code',
        'email_verification_expires_at',
        'agreed_to_terms_version',
        'nin_verification',
        'bvn_verification',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'login_status' => 'boolean',
        'last_login' => 'datetime',
        'last_logout' => 'datetime',
        'nin_verification' => 'integer',
        'bvn_verification' => 'integer',
        'latitude' => 'float',
        'longitude' => 'float',
    ];



    /**
     * Generate a unique 6-digit agent ID.
     */
    private static function generateUniqueAgentId()
    {
        do {
            $agent_id = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        } while (self::where('agent_id', $agent_id)->exists());

        return $agent_id;
    }

    /**
     * Get the agent's additional information.
     */
    public function information()
    {
        return $this->hasOne(AgentInformation::class, 'agent_id', 'agent_id');
    }

    /**
     * Get the properties for the agent.
     */
    public function properties()
    {
        return $this->hasMany(Property::class, 'agent_id', 'agent_id');
    }

    /**
     * Get the agent's device tokens.
     */
    public function deviceTokens()
    {
        return $this->morphMany(DeviceToken::class, 'tokenable');
    }

    /**
     * Get the notification settings for the agent.
     */
    public function notificationSettings()
    {
        return $this->morphOne(NotificationSetting::class, 'user', 'user_type', 'user_id');
    }

    /**
     * Get the reviews for the agent.
     */
    public function reviews()
    {
        return $this->hasMany(AgentReview::class, 'agent_id', 'agent_id');
    }
}
