<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WithdrawalRequest extends Model
{
    protected $table = 'withdrawal_requests';

    protected $fillable = [
        'user_id',
        'user_type',
        'wallet_transaction_id',
        'recipient_id',
        'amount',
        'fee',
        'net_amount',
        'currency',
        'reference',
        'paystack_transfer_code',
        'paystack_reference',
        'status',
        'failure_reason',
        'processed_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'fee' => 'decimal:2',
        'net_amount' => 'decimal:2',
        'processed_at' => 'datetime',
    ];

    // Status constants
    const STATUS_PENDING = 'pending';
    const STATUS_PROCESSING = 'processing';
    const STATUS_SUCCESS = 'success';
    const STATUS_FAILED = 'failed';
    const STATUS_REVERSED = 'reversed';

    /**
     * Get the transfer recipient
     */
    public function recipient(): BelongsTo
    {
        return $this->belongsTo(TransferRecipient::class, 'recipient_id');
    }

    /**
     * Get the wallet transaction
     */
    public function walletTransaction(): BelongsTo
    {
        return $this->belongsTo(WalletTransaction::class, 'wallet_transaction_id');
    }

    /**
     * Generate a unique reference
     */
    public static function generateReference(): string
    {
        return 'WR_' . uniqid() . '_' . time();
    }

    /**
     * Mark as processing with Paystack transfer code
     */
    public function markProcessing(string $transferCode, ?string $paystackReference = null): bool
    {
        $this->status = self::STATUS_PROCESSING;
        $this->paystack_transfer_code = $transferCode;
        if ($paystackReference) {
            $this->paystack_reference = $paystackReference;
        }
        return $this->save();
    }

    /**
     * Mark as successful
     */
    public function markSuccess(): bool
    {
        $this->status = self::STATUS_SUCCESS;
        $this->processed_at = now();
        return $this->save();
    }

    /**
     * Mark as failed
     */
    public function markFailed(string $reason): bool
    {
        $this->status = self::STATUS_FAILED;
        $this->failure_reason = $reason;
        $this->processed_at = now();
        return $this->save();
    }

    /**
     * Check if withdrawal is still pending or processing
     */
    public function isPending(): bool
    {
        return in_array($this->status, [self::STATUS_PENDING, self::STATUS_PROCESSING]);
    }
}
