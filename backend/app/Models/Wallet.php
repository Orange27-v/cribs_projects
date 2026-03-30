<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Wallet extends Model
{
    protected $table = 'wallets';

    protected $fillable = [
        'user_id',
        'user_type',
        'available_balance',
        'pending_balance',
        'total_earned',
        'total_withdrawn',
        'currency',
    ];

    protected $casts = [
        'available_balance' => 'float',
        'pending_balance' => 'float',
        'total_earned' => 'float',
        'total_withdrawn' => 'float',
    ];

    /**
     * Get wallet transactions
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(WalletTransaction::class, 'wallet_id');
    }

    /**
     * Get or create wallet for a user/agent
     */
    public static function getOrCreate(int $userId, string $userType = 'agent'): self
    {
        return self::firstOrCreate(
            [
                'user_id' => $userId,
                'user_type' => $userType,
            ],
            [
                'available_balance' => 0.00,
                'pending_balance' => 0.00,
                'total_earned' => 0.00,
                'total_withdrawn' => 0.00,
                'currency' => 'NGN',
            ]
        );
    }

    /**
     * Add funds to available balance
     */
    public function credit(float $amount): bool
    {
        $this->available_balance += $amount;
        $this->total_earned += $amount;
        return $this->save();
    }

    /**
     * Deduct funds from available balance
     */
    public function debit(float $amount): bool
    {
        if ($this->available_balance < $amount) {
            return false;
        }

        $this->available_balance -= $amount;
        return $this->save();
    }

    /**
     * Move funds to pending (escrow hold)
     */
    public function holdInEscrow(float $amount): bool
    {
        if ($this->available_balance < $amount) {
            return false;
        }

        $this->available_balance -= $amount;
        $this->pending_balance += $amount;
        return $this->save();
    }

    /**
     * Release funds from pending to available
     */
    public function releaseFromEscrow(float $amount): bool
    {
        if ($this->pending_balance < $amount) {
            return false;
        }

        $this->pending_balance -= $amount;
        $this->available_balance += $amount;
        return $this->save();
    }

    /**
     * Record a withdrawal
     */
    public function recordWithdrawal(float $amount): bool
    {
        $this->total_withdrawn += $amount;
        return $this->save();
    }

    /**
     * Refund a failed withdrawal
     */
    public function refundWithdrawal(float $amount): bool
    {
        $this->available_balance += $amount;
        $this->total_withdrawn -= $amount;
        return $this->save();
    }


    /**
     * Check if user can withdraw specified amount
     */
    public function canWithdraw(float $amount): bool
    {
        return $this->available_balance >= $amount;
    }

    /**
     * Get total balance (available + pending)
     */
    public function getTotalBalanceAttribute(): float
    {
        return $this->available_balance + $this->pending_balance;
    }
}
