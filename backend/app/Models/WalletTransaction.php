<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletTransaction extends Model
{
    protected $table = 'wallet_transactions';

    protected $fillable = [
        'wallet_id',
        'user_id',
        'user_type',
        'transaction_type',
        'amount',
        'fee',
        'net_amount',
        'balance_before',
        'balance_after',
        'currency',
        'reference',
        'paystack_reference',
        'recipient_code',
        'related_transaction_id',
        'related_inspection_id',
        'status',
        'failure_reason',
        'description',
        'metadata',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'fee' => 'decimal:2',
        'net_amount' => 'decimal:2',
        'balance_before' => 'decimal:2',
        'balance_after' => 'decimal:2',
        'metadata' => 'array',
    ];

    // Transaction types
    const TYPE_DEPOSIT = 'deposit';
    const TYPE_WITHDRAWAL = 'withdrawal';
    const TYPE_REFUND = 'refund';
    const TYPE_ESCROW_RELEASE = 'escrow_release';
    const TYPE_ESCROW_HOLD = 'escrow_hold';
    const TYPE_PLATFORM_FEE = 'platform_fee';

    // Status constants
    const STATUS_PENDING = 'pending';
    const STATUS_PROCESSING = 'processing';
    const STATUS_SUCCESS = 'success';
    const STATUS_FAILED = 'failed';
    const STATUS_REVERSED = 'reversed';

    /**
     * Get the wallet this transaction belongs to
     */
    public function wallet(): BelongsTo
    {
        return $this->belongsTo(Wallet::class, 'wallet_id');
    }

    /**
     * Generate a unique reference
     */
    public static function generateReference(string $prefix = 'WT'): string
    {
        return $prefix . '_' . uniqid() . '_' . time();
    }

    /**
     * Create a deposit transaction
     */
    public static function createDeposit(
        Wallet $wallet,
        float $amount,
        float $fee = 0,
        string $description,
        ?string $paystackReference = null,
        ?int $relatedTransactionId = null,
        ?int $relatedInspectionId = null
    ): self {
        $balanceBefore = $wallet->available_balance;
        $netAmount = $amount - $fee;
        $balanceAfter = $balanceBefore + $netAmount;

        return self::create([
            'wallet_id' => $wallet->id,
            'user_id' => $wallet->user_id,
            'user_type' => $wallet->user_type,
            'transaction_type' => self::TYPE_DEPOSIT,
            'amount' => $netAmount,
            'fee' => $fee,
            'net_amount' => $netAmount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'currency' => $wallet->currency,
            'reference' => self::generateReference('DEP'),
            'paystack_reference' => $paystackReference,
            'related_transaction_id' => $relatedTransactionId,
            'related_inspection_id' => $relatedInspectionId,
            'status' => self::STATUS_SUCCESS,
            'description' => $description,
        ]);
    }

    /**
     * Create a withdrawal transaction
     */
    public static function createWithdrawal(
        Wallet $wallet,
        float $amount,
        float $fee,
        string $recipientCode,
        string $description
    ): self {
        $balanceBefore = $wallet->available_balance;
        $netAmount = $amount - $fee;
        $balanceAfter = $balanceBefore - $amount;

        return self::create([
            'wallet_id' => $wallet->id,
            'user_id' => $wallet->user_id,
            'user_type' => $wallet->user_type,
            'transaction_type' => self::TYPE_WITHDRAWAL,
            'amount' => $amount,
            'fee' => $fee,
            'net_amount' => $netAmount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'currency' => $wallet->currency,
            'reference' => self::generateReference('WDR'),
            'recipient_code' => $recipientCode,
            'status' => self::STATUS_PENDING,
            'description' => $description,
        ]);
    }

    /**
     * Create a refund transaction
     */
    public static function createRefund(
        Wallet $wallet,
        float $amount,
        string $description,
        ?int $relatedTransactionId = null
    ): self {
        $balanceBefore = $wallet->available_balance;
        $balanceAfter = $balanceBefore + $amount;

        return self::create([
            'wallet_id' => $wallet->id,
            'user_id' => $wallet->user_id,
            'user_type' => $wallet->user_type,
            'transaction_type' => self::TYPE_REFUND,
            'amount' => $amount,
            'fee' => 0,
            'net_amount' => $amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'currency' => $wallet->currency,
            'reference' => self::generateReference('REF'),
            'related_transaction_id' => $relatedTransactionId,
            'status' => self::STATUS_SUCCESS,
            'description' => $description,
        ]);
    }

    /**
     * Create an escrow release transaction
     */
    public static function createEscrowRelease(
        Wallet $wallet,
        float $amount,
        string $description,
        ?int $relatedInspectionId = null
    ): self {
        $balanceBefore = $wallet->available_balance;
        $balanceAfter = $balanceBefore + $amount;

        return self::create([
            'wallet_id' => $wallet->id,
            'user_id' => $wallet->user_id,
            'user_type' => $wallet->user_type,
            'transaction_type' => self::TYPE_ESCROW_RELEASE,
            'amount' => $amount,
            'fee' => 0,
            'net_amount' => $amount,
            'balance_before' => $balanceBefore,
            'balance_after' => $balanceAfter,
            'currency' => $wallet->currency,
            'reference' => self::generateReference('ESC'),
            'related_inspection_id' => $relatedInspectionId,
            'status' => self::STATUS_SUCCESS,
            'description' => $description,
        ]);
    }

    /**
     * Mark transaction as successful
     */
    public function markSuccess(?string $paystackReference = null): bool
    {
        $this->status = self::STATUS_SUCCESS;
        if ($paystackReference) {
            $this->paystack_reference = $paystackReference;
        }
        return $this->save();
    }

    /**
     * Mark transaction as failed
     */
    public function markFailed(string $reason): bool
    {
        $this->status = self::STATUS_FAILED;
        $this->failure_reason = $reason;
        return $this->save();
    }

    /**
     * Check if transaction is a credit (adds to balance)
     */
    public function isCredit(): bool
    {
        return in_array($this->transaction_type, [
            self::TYPE_DEPOSIT,
            self::TYPE_REFUND,
            self::TYPE_ESCROW_RELEASE,
        ]);
    }

    /**
     * Check if transaction is a debit (reduces balance)
     */
    public function isDebit(): bool
    {
        return in_array($this->transaction_type, [
            self::TYPE_WITHDRAWAL,
            self::TYPE_ESCROW_HOLD,
            self::TYPE_PLATFORM_FEE,
        ]);
    }
}
