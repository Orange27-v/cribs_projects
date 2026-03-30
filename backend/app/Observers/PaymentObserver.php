<?php

namespace App\Observers;

use App\Models\Transaction;
use App\Jobs\SendPaymentConfirmationNotificationJob; // Import the job
use Illuminate\Support\Facades\Log;

class PaymentObserver
{
    /**
     * Handle the Transaction "created" event.
     *
     * @param  \App\Models\Transaction  $transaction
     * @return void
     */
    public function created(Transaction $transaction)
    {
        Log::info("PaymentObserver 'created' method called for transaction ID: {$transaction->id}");
        // Dispatch job only if payment is successful
        if ($transaction->status === 'paid') {
            SendPaymentConfirmationNotificationJob::dispatch($transaction->id);
        }
    }

    /**
     * Handle the Transaction "updated" event.
     *
     * @param  \App\Models\Transaction  $transaction
     * @return void
     */
    public function updated(Transaction $transaction)
    {
        Log::info("PaymentObserver 'updated' method called for transaction ID: {$transaction->id}");
        // Dispatch job only if status changed to 'paid'
        if ($transaction->isDirty('status') && $transaction->status === 'paid') {
            SendPaymentConfirmationNotificationJob::dispatch($transaction->id);
        }
    }

    /**
     * Handle the Transaction "deleted" event.
     *
     * @param  \App\Models\Transaction  $transaction
     * @return void
     */
    public function deleted(Transaction $transaction)
    {
        //
    }

    /**
     * Handle the Transaction "restored" event.
     *
     * @param  \App\Models\Transaction  $transaction
     * @return void
     */
    public function restored(Transaction $transaction)
    {
        //
    }

    /**
     * Handle the Transaction "force deleted" event.
     *
     * @param  \App\Models\Transaction  $transaction
     * @return void
     */
    public function forceDeleted(Transaction $transaction)
    {
        //
    }
}
