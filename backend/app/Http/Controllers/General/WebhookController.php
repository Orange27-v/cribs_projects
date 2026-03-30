<?php

namespace App\Http\Controllers\General;

use App\Events\VerificationUpdated;
use App\Models\Inspection;
use App\Models\Transaction;
use App\Models\User;
use App\Models\Verification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use App\Http\Controllers\Controller;

class WebhookController extends Controller
{
    public function handleQoreIdWebhook(Request $request)
    {
        try {
            // Handle GET request for webhook verification
            if ($request->isMethod('get')) {
                return response()->json(['status' => 'success', 'message' => 'Webhook URL is active and ready to receive POST requests.']);
            }

            // Handle QoreID's validation POST request which contains an empty JSON object.
            // This must be checked before signature verification.
            if ($request->getContent() === '{}') {
                Log::info('QoreID webhook validation request received.');
                return response()->json(['status' => 'success', 'message' => 'Webhook validation successful.']);
            }

            if (!$this->verifyQoreIdWebhookSignature($request)) {
                Log::warning('QoreID webhook signature verification failed.');
                return response()->json(['status' => 'error', 'message' => 'Signature verification failed'], 401);
            }

            $payload = $request->all();
            Log::info('QoreID webhook received:', $payload);

            // If the payload is empty, acknowledge it with a 200 OK, but log a warning.
            // This allows QoreID to successfully configure the webhook even with empty test payloads.
            if (empty($payload)) {
                Log::warning('QoreID webhook received an empty payload. Acknowledging with 200 OK, but no processing will occur.');
                return response()->json(['status' => 'success', 'message' => 'Empty payload received, no processing done.']);
            }

            $customerReference = $payload['customerReference'] ?? null;
            if (!$customerReference) {
                Log::warning('QoreID webhook is missing customerReference.', $payload);
                return response()->json(['status' => 'error', 'message' => 'Missing customerReference'], 400);
            }

            $verification = Verification::where('qoreid_reference', $customerReference)->first();

            if (!$verification) {
                Log::warning('No verification found for QoreID customerReference: ' . $customerReference);
                return response()->json(['status' => 'error', 'message' => 'Verification not found'], 404);
            }

            // Determine the status from the payload. This might need adjustment based on actual QoreID payloads.
            $newStatus = $payload['status']['status'] ?? $payload['summary']['v_nin_check']['status'] ?? 'failed';

            $verification->update([
                'status' => $newStatus,
                'response_payload' => $payload,
            ]);

            // Fire an event to notify the user via WebSockets
            event(new VerificationUpdated($verification));

            Log::info('Successfully updated verification status from QoreID webhook for reference: ' . $customerReference);

            return response()->json(['status' => 'success']);
        } catch (\Exception $e) {
            Log::error('QoreID webhook processing failed: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while processing the webhook.'
            ], 500);
        }
    }

    public function handleWebhook(Request $request)
    {
        try {
            // Verify the webhook signature
            $paystackSecret = env('PAYSTACK_SECRET_KEY');
            if (!$this->verifyWebhookSignature($request, $paystackSecret)) {
                Log::warning('Paystack webhook signature verification failed.');

                return response()->json(['status' => 'error', 'message' => 'Signature verification failed'], 401);
            }

            $payload = $request->all();
            Log::info('Paystack webhook received:', $payload);

            if ($payload['event'] === 'charge.success') {
                $reference = $payload['data']['reference'];
                $amount = $payload['data']['amount'] / 100;

                $lockKey = 'finalize_booking_' . $reference;
                $lock = Cache::lock($lockKey, 15);

                if (!$lock->get()) {
                    Log::info("Webhook charge.success lock already acquired for reference: $reference");
                    return response()->json(['status' => 'success', 'message' => 'Transaction already processing']);
                }

                try {
                    // Check if transaction already exists
                    if (Transaction::where('payment_reference', $reference)->exists()) {
                        Log::info("Transaction with reference $reference already exists. Skipping.");

                        return response()->json(['status' => 'success', 'message' => 'Transaction already processed']);
                    }

                    $metadata = $payload['data']['metadata'] ?? null;
                    if (!$metadata) {
                        Log::error("Webhook for reference $reference has no metadata. Cannot create booking.");

                        return response()->json(['status' => 'error', 'message' => 'Missing metadata'], 400);
                    }

                    $agentId = $metadata['agent_id'] ?? null;
                    $propertyId = $metadata['property_id'] ?? null;
                    $inspectionDate = $metadata['inspection_date'] ?? null;
                    $inspectionTime = $metadata['inspection_time'] ?? null;
                    $userId = $metadata['user_id'] ?? null;

                    if (!$agentId || !$inspectionDate || !$inspectionTime || !$userId) {
                        Log::error("Webhook for reference $reference is missing required metadata fields.");

                        return response()->json(['status' => 'error', 'message' => 'Missing required metadata'], 400);
                    }

                    $user = User::find($userId);
                    if (!$user) {
                        Log::error("User with ID $userId not found for webhook reference $reference.");

                        return response()->json(['status' => 'error', 'message' => 'User not found'], 404);
                    }

                    // Get platform fee from metadata
                    $platformFee = $metadata['platform_fee'] ?? 0;

                    // Fallback: If metadata fee is missing/zero, fetch from system settings
                    if ($platformFee <= 0) {
                        $platformSetting = DB::table('platform_settings')->where('key_name', 'platform_fee')->first();
                        if ($platformSetting) {
                            $platformFee = (float) $platformSetting->value;
                        }
                    }

                    // Calculate booking fee (agent's portion)
                    $bookingFee = ($amount > $platformFee) ? ($amount - $platformFee) : $amount;

                    try {
                        DB::transaction(function () use ($user, $agentId, $propertyId, $inspectionDate, $inspectionTime, $amount, $bookingFee, $platformFee, $reference, $payload) {
                            $agent = DB::table('cribs_agents')->where('agent_id', $agentId)->first();

                            if (!$agent) {
                                Log::error("Agent not found during webhook booking. Agent ID: $agentId");
                                throw new \Exception("Agent with ID $agentId not found.");
                            }

                            // Create Transaction Record
                            $transaction = Transaction::create([
                                'payer_id' => $user->user_id,
                                'payee_id' => $agent->agent_id,
                                'amount' => $bookingFee, // Agent's booking fee only
                                'currency' => $payload['data']['currency'] ?? 'NGN',
                                'payment_reference' => $reference,
                                'gateway' => 'paystack',
                                'channel' => $payload['data']['channel'] ?? 'webhook',
                                'status' => $payload['data']['status'] ?? 'success',
                                'escrow_status' => 1, // Pending in escrow
                            ]);

                            // Create Inspection Record
                            $inspection = Inspection::create([
                                'user_id' => $user->user_id,
                                'agent_id' => $agent->agent_id,
                                'property_id' => $propertyId,
                                'transaction_id' => $transaction->id,
                                'inspection_date' => $inspectionDate,
                                'inspection_time' => $inspectionTime,
                                'status' => 'scheduled',
                                'amount' => $bookingFee, // Agent's booking fee only
                                'payment_status' => 'paid',
                                'payment_method' => 'webhook',
                            ]);

                            // === ESCROW HOLD: Add to agent's pending balance ===
                            // Get or create agent wallet
                            $wallet = DB::table('wallets')
                                ->where('user_id', $agent->agent_id)
                                ->where('user_type', 'agent')
                                ->first();

                            if (!$wallet) {
                                // Create wallet for agent if not exists
                                $walletId = DB::table('wallets')->insertGetId([
                                    'user_id' => $agent->agent_id,
                                    'user_type' => 'agent',
                                    'available_balance' => 0,
                                    'pending_balance' => 0,
                                    'total_earned' => 0,
                                    'total_withdrawn' => 0,
                                    'currency' => 'NGN',
                                    'created_at' => now(),
                                    'updated_at' => now(),
                                ]);
                                $wallet = DB::table('wallets')->find($walletId);
                            }

                            // Create escrow_hold wallet transaction
                            $escrowReference = 'ESC_HOLD_' . Str::random(12) . '_' . time();
                            DB::table('wallet_transactions')->insert([
                                'wallet_id' => $wallet->id,
                                'user_id' => $agent->agent_id,
                                'user_type' => 'agent',
                                'transaction_type' => 'escrow_hold',
                                'amount' => $bookingFee,
                                'fee' => 0,
                                'net_amount' => $bookingFee,
                                'balance_before' => $wallet->pending_balance,
                                'balance_after' => $wallet->pending_balance + $bookingFee,
                                'currency' => 'NGN',
                                'reference' => $escrowReference,
                                'related_transaction_id' => $transaction->id,
                                'related_inspection_id' => $inspection->id,
                                'status' => 'pending',
                                'description' => 'Inspection fee held in escrow - awaiting completion via Webhook',
                                'metadata' => json_encode([
                                    'user_name' => "{$user->first_name} {$user->last_name}",
                                    'property_id' => $propertyId,
                                    'inspection_date' => $inspectionDate,
                                ]),
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]);

                            // Update agent's pending balance
                            DB::table('wallets')
                                ->where('id', $wallet->id)
                                ->increment('pending_balance', $bookingFee);

                            // Log Platform Fee
                            if ($platformFee > 0) {
                                DB::table('platform_fee_logs')->insert([
                                    'transaction_reference' => $reference,
                                    'source_app' => 'webhook',
                                    'user_id' => $user->user_id,
                                    'amount' => $platformFee,
                                    'description' => 'Platform fee for Inspection Booking',
                                    'created_at' => now(),
                                ]);
                            }
                        });

                        Log::info("Successfully created booking from webhook for reference: $reference");

                        return response()->json(['status' => 'success', 'message' => 'Webhook processed successfully']);
                    } catch (\Exception $e) {
                        Log::error('Webhook Booking Creation Exception: ' . $e->getMessage());

                        return response()->json(['status' => 'error', 'message' => 'An error occurred during booking creation.'], 500);
                    }
                } finally {
                    $lock->release();
                }
            }

            if ($payload['event'] === 'transfer.success') {
                $reference = $payload['data']['reference'];
                $withdrawalRequest = \App\Models\WithdrawalRequest::where('reference', $reference)->first();

                if ($withdrawalRequest && $withdrawalRequest->isPending()) {
                    $withdrawalRequest->markSuccess();

                    $walletTransaction = $withdrawalRequest->walletTransaction;
                    if ($walletTransaction) {
                        $walletTransaction->markSuccess($payload['data']['reference'] ?? null);
                    }

                    // Send Notification
                    \App\Helpers\NotificationHelper::sendAgentNotification(
                        $withdrawalRequest->user_id,
                        'withdrawal_successful',
                        'Withdrawal Successful',
                        "Your withdrawal of ₦" . number_format((float) $withdrawalRequest->net_amount, 2) . " has been successfully sent to your bank account."
                    );

                    // Send Email
                    if ($withdrawalRequest->user_type === 'agent') {
                        $agent = \App\Models\Agent::find($withdrawalRequest->user_id);
                        if ($agent) {
                            $withdrawalData = [
                                'userName' => $agent->first_name ?: 'Agent',
                                'netAmount' => (float) $withdrawalRequest->net_amount,
                                'bankName' => $withdrawalRequest->recipient->bank_name,
                                'accountNumber' => $withdrawalRequest->recipient->masked_account_number,
                                'reference' => $withdrawalRequest->reference,
                            ];
                            \Illuminate\Support\Facades\Mail::to($agent->email)->send(new \App\Mail\WithdrawalSuccessfulMail($withdrawalData));
                        }
                    }
                }
                return response()->json(['status' => 'success', 'message' => 'Withdrawal success processed']);
            }

            if ($payload['event'] === 'transfer.failed') {
                $reference = $payload['data']['reference'];
                $withdrawalRequest = \App\Models\WithdrawalRequest::where('reference', $reference)->first();

                if ($withdrawalRequest && $withdrawalRequest->isPending()) {
                    $reason = $payload['data']['reason'] ?? 'Transfer failed';
                    $withdrawalRequest->markFailed($reason);

                    // Refund logic
                    $walletTransaction = $withdrawalRequest->walletTransaction;
                    if ($walletTransaction) {
                        $walletTransaction->markFailed($reason);

                        $wallet = $walletTransaction->wallet;
                        $wallet->refundWithdrawal((float) $walletTransaction->amount);

                        \App\Models\WalletTransaction::createRefund(
                            $wallet,
                            (float) $walletTransaction->amount,
                            'Refund for failed withdrawal: ' . $withdrawalRequest->reference,
                            $walletTransaction->id
                        );
                    }

                    // Notifications
                    \App\Helpers\NotificationHelper::sendAgentNotification(
                        $withdrawalRequest->user_id,
                        'withdrawal_failed',
                        'Withdrawal Failed',
                        "Your withdrawal of ₦" . number_format((float) $withdrawalRequest->amount, 2) . " failed. The amount has been refunded to your wallet."
                    );


                    if ($withdrawalRequest->user_type === 'agent') {
                        $agent = \App\Models\Agent::find($withdrawalRequest->user_id);
                        if ($agent) {
                            $withdrawalData = [
                                'userName' => $agent->first_name ?: 'Agent',
                                'amount' => (float) $withdrawalRequest->amount,
                                'reason' => $reason,
                                'reference' => $withdrawalRequest->reference,
                            ];
                            \Illuminate\Support\Facades\Mail::to($agent->email)->send(new \App\Mail\WithdrawalFailedMail($withdrawalData));
                        }
                    }
                }
                return response()->json(['status' => 'success', 'message' => 'Withdrawal failure processed']);
            }

            return response()->json(['status' => 'success', 'message' => 'Webhook received']);
        } catch (\Exception $e) {
            Log::error('Paystack webhook processing failed: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while processing the webhook.'
            ], 500);
        }
    }

    private function verifyWebhookSignature(Request $request, $paystackSecret)
    {
        $signature = $request->header('x-paystack-signature');
        if (!$signature) {
            return false;
        }

        $payload = $request->getContent();
        $hash = hash_hmac('sha512', $payload, $paystackSecret);

        return $hash === $signature;
    }

    private function verifyQoreIdWebhookSignature(Request $request)
    {
        $signature = $request->header('X-Qoreid-Signature'); // QoreID header
        $secret = config('qoreid.webhook_secret');

        if (!$signature) {
            Log::warning('QoreID webhook: Missing X-Qoreid-Signature header.');
            return false;
        }

        if (!$secret) {
            Log::error('QoreID webhook: Missing QOREID_WEBHOOK_SECRET in env.');
            return false;
        }

        // Raw body (exact string QoreID signs)
        $payload = $request->getContent();

        // QoreID uses SHA256 (not sha512)
        $generatedHash = hash_hmac('sha256', $payload, $secret);

        $isValid = hash_equals($generatedHash, $signature);

        Log::debug('QoreID signature check', [
            'incoming_signature' => $signature,
            'generated_hash' => $generatedHash,
            'match' => $isValid,
            'payload' => $payload
        ]);

        return $isValid;
    }
}
