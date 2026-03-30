<?php

namespace App\Jobs;

use App\Models\Transaction;
use App\Models\Notification;
use App\Services\FCMService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendPaymentConfirmationNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected int $transactionId;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct(int $transactionId)
    {
        $this->transactionId = $transactionId;
    }

    /**
     * Execute the job.
     *
     * @param  \App\Services\FCMService  $fcmService
     * @return void
     */
    public function handle(FCMService $fcmService)
    {
        Log::info("SendPaymentConfirmationNotificationJob started for transaction ID: {$this->transactionId}");

        $transaction = Transaction::with(['payer', 'payee'])->find($this->transactionId);

        if (!$transaction) {
            Log::warning("Transaction {$this->transactionId} not found. Skipping notification.");
            return;
        }

        $title = "Payment Confirmed!";
        $body = "Your payment of {$transaction->currency} {$transaction->amount} has been successfully processed.";
        $data = [
            'transactionId' => (string)$transaction->id,
            'type' => 'payment_confirmation',
            'status' => $transaction->status,
        ];

        // Notify the payer (user)
        if ($transaction->payer && $transaction->payer->notificationSettings->push_notifications_enabled) {
            Notification::create([
                'receiver_id' => $transaction->payer->id,
                'receiver_type' => 'user',
                'type' => 'payment_confirmation',
                'title' => $title,
                'body' => $body,
                'data' => $data,
                'is_read' => false,
            ]);

            $fcmService->sendToUserOrAgent(
                $transaction->payer->id,
                'user',
                $title,
                $body,
                $data
            );
            Log::info("Payment confirmation notification sent to payer {$transaction->payer->id} for transaction ID: {$this->transactionId}");
        }

        // Notify the payee (agent)
        if ($transaction->payee && $transaction->payee->notificationSettings->push_notifications_enabled) {
            $agentTitle = "Payment Received!";
            $agentBody = "You have received a payment of {$transaction->currency} {$transaction->amount} from {$transaction->payer->full_name}.";
            $agentData = [
                'transactionId' => (string)$transaction->id,
                'type' => 'payment_received',
                'status' => $transaction->status,
            ];

            Notification::create([
                'receiver_id' => $transaction->payee->id,
                'receiver_type' => 'agent',
                'type' => 'payment_received',
                'title' => $agentTitle,
                'body' => $agentBody,
                'data' => $agentData,
                'is_read' => false,
            ]);

            $fcmService->sendToUserOrAgent(
                $transaction->payee->id,
                'agent',
                $agentTitle,
                $agentBody,
                $agentData
            );
            Log::info("Payment received notification sent to payee {$transaction->payee->id} for transaction ID: {$this->transactionId}");
        }
    }
}
