<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FirebaseToken extends Model
{
    use HasFactory;

    protected $table = 'firebase_tokens';

    protected $fillable = [
        'fcm_token',
        'tokenable_id',
        'tokenable_type',
    ];

    /**
     * Get the parent tokenable model (user or agent).
     */
    public function tokenable()
    {
        return $this->morphTo();
    }
}
