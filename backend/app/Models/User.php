<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'cribs_users';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',  // Added: user_id (bigint)
        'first_name',
        'last_name',
        'email',
        'phone',
        'password',
        'area',
        'latitude',
        'longitude',
        'login_status',
        'last_login',
        'last_logout',
        'profile_picture_url',
        'agreed_to_terms_version',
        'email_verified',
        'email_verification_code',
        'email_verification_expires_at',
        'nin_verification',
        'bvn_verification',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array
     */
    protected $appends = ['full_name'];

    /**
     * Get the user's full name.
     *
     * @return string
     */
    public function getFullNameAttribute()
    {
        return "{$this->first_name} {$this->last_name}";
    }

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'user_id' => 'integer',  // Cast user_id as integer (bigint)
        'nin_verification' => 'integer',
        'bvn_verification' => 'integer',
    ];



    /**
     * Generate a unique 6-digit user ID.
     */
    private static function generateUniqueUserId()
    {
        do {
            $user_id = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        } while (self::where('user_id', $user_id)->exists());

        return $user_id;
    }

    /**
     * Get the saved properties for the user.
     */
    public function savedProperties()
    {
        return $this->belongsToMany(Property::class, 'saved_properties', 'user_id', 'property_id', 'id', 'property_id');
    }

    /**
     * Get the saved agents for the user.
     */
    public function savedAgents()
    {
        return $this->belongsToMany(Agent::class, 'saved_agents', 'user_id', 'agent_id', 'id', 'agent_id');
    }

    /**
     * Get the user's Firebase tokens (old).
     */
    public function firebaseTokens()
    {
        return $this->morphMany(FirebaseToken::class, 'tokenable');
    }

    /**
     * Get the user's device tokens (new).
     */
    public function deviceTokens()
    {
        return $this->morphMany(DeviceToken::class, 'tokenable');
    }

    /**
     * Get the notification settings for the user.
     */
    public function notificationSettings()
    {
        return $this->morphOne(NotificationSetting::class, 'user', 'user_type', 'user_id');
    }
}
