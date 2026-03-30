<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TransferRecipient extends Model
{
    protected $table = 'transfer_recipients';

    protected $fillable = [
        'user_id',
        'user_type',
        'recipient_code',
        'bank_code',
        'bank_name',
        'account_number',
        'account_name',
        'is_default',
        'is_active',
    ];

    protected $casts = [
        'is_default' => 'boolean',
        'is_active' => 'boolean',
    ];

    protected $hidden = [
        'recipient_code', // Hide from JSON by default for security
    ];

    /**
     * Get masked account number for display
     */
    public function getMaskedAccountNumberAttribute(): string
    {
        $length = strlen($this->account_number);
        if ($length <= 4) {
            return $this->account_number;
        }

        return str_repeat('*', $length - 4) . substr($this->account_number, -4);
    }

    /**
     * Get the recipient code (explicit method for when needed)
     */
    public function getRecipientCode(): string
    {
        return $this->recipient_code;
    }

    /**
     * Set this recipient as default and unset others
     */
    public function setAsDefault(): bool
    {
        // Unset all other defaults for this user
        self::where('user_id', $this->user_id)
            ->where('user_type', $this->user_type)
            ->where('id', '!=', $this->id)
            ->update(['is_default' => false]);

        $this->is_default = true;
        return $this->save();
    }

    /**
     * Deactivate this recipient
     */
    public function deactivate(): bool
    {
        $this->is_active = false;
        return $this->save();
    }

    /**
     * Get default recipient for a user
     */
    public static function getDefault(int $userId, string $userType = 'agent'): ?self
    {
        return self::where('user_id', $userId)
            ->where('user_type', $userType)
            ->where('is_active', true)
            ->where('is_default', true)
            ->first();
    }

    /**
     * Get all active recipients for a user
     */
    public static function getForUser(int $userId, string $userType = 'agent')
    {
        return self::where('user_id', $userId)
            ->where('user_type', $userType)
            ->where('is_active', true)
            ->orderBy('is_default', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();
    }
}
