<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\FCMService;
use App\Http\Controllers\User\PaystackController;
use App\Models\Inspection;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Cache;

class BookingFinalizationController extends Controller
{
    protected $paystackController;
    protected $fcmService;

    public function __construct(PaystackController $paystackController, FCMService $fcmService)
    {
        $this->paystackController = $paystackController;
        $this->fcmService = $fcmService;
    }

    public function finalizeBooking(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'agent_id' => 'required|exists:cribs_agents,agent_id',
                'property_id' => 'nullable|exists:properties,id',
                'paystack_reference' => 'required|string',
                'inspection_date' => 'required|date',
                'inspection_time' => 'required|date_format:H:i',
                'amount' => 'required|numeric',
                'payment_method' => 'required|string', // e.g., 'card', 'bank_transfer'
            ]);

            if ($validator->fails()) {
                return response()->json($validator->errors(), 422);
            }

            $user = Auth::user();
            if (!$user) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $paystackReference = $request->paystack_reference;
            $amount = $request->amount;
            $agentId = $request->agent_id;
            $propertyId = $request->property_id;
            $inspectionDate = $request->inspection_date;
            $inspectionTime = $request->inspection_time;
            $paymentMethod = $request->payment_method;

            // 1. Verify Paystack Transaction
            $paystackData = $this->paystackController->verifyTransaction($paystackReference);

            if (!$paystackData) {
                Log::warning("Failed Paystack verification for reference: $paystackReference. Paystack returned null.");
                return response()->json(['message' => 'Payment verification failed. Transaction not found.'], 400);
            }

            // Check amount match - verify against Paystack's actual payment amount
            $paystackAmount = isset($paystackData['amount']) ? $paystackData['amount'] / 100 : 0;

            // Get platform fee from metadata (sent during payment initialization)
            $platformFee = $paystackData['metadata']['platform_fee'] ?? 0;

            // Fallback: If metadata fee is missing/zero, fetch from system settings
            if ($platformFee <= 0) {
                $platformSetting = DB::table('platform_settings')->where('key_name', 'platform_fee')->first();
                if ($platformSetting) {
                    $platformFee = (float) $platformSetting->value;
                }
            }

            // Calculate expected total: amount from request should be total paid (or we accept booking fee only)
            // If client sends booking fee only, we need to add platform fee to match Paystack amount
            $expectedTotal = $amount + $platformFee;

            // Accept if: amount matches exactly OR booking_fee + platform_fee matches
            if ($amount != $paystackAmount && $expectedTotal != $paystackAmount) {
                Log::warning("Amount mismatch for reference: $paystackReference. Sent: $amount, Platform Fee: $platformFee, Expected Total: $expectedTotal, Actual Paystack: $paystackAmount");
                return response()->json(['message' => 'Payment verification failed: amount mismatch.'], 400);
            }

            // Calculate the actual booking fee (agent's fee) - what goes to the agent/inspection
            // If amount matches Paystack (total was sent), subtract platform fee
            // If expectedTotal matches (booking fee was sent), use amount directly
            $bookingFee = ($amount == $paystackAmount) ? ($amount - $platformFee) : $amount;

            // Ensure the verified transaction is for the correct user (optional but good practice)
            // This assumes Paystack returns the customer email/id in the verification data
            if (isset($paystackData['customer']['email']) && strtolower(trim($paystackData['customer']['email'])) !== strtolower(trim($user->email))) {
                Log::warning("Paystack verification customer email mismatch for reference: $paystackReference. Expected: {$user->email}, Actual: {$paystackData['customer']['email']}");
                // return response()->json(['message' => 'Payment verification failed: customer mismatch.'], 400); 
                // Warning: Sometimes Paystack emails might differ slightly or be absent. 
                // We'll log it but maybe continue if reference matches.
            }

            // 2. Check if transaction already exists (idempotency check) with a lock
            $lockKey = 'finalize_booking_' . $paystackReference;
            $lock = Cache::lock($lockKey, 15);

            if (!$lock->get()) {
                Log::info("Booking finalization lock already acquired for reference: $paystackReference");
                return response()->json([
                    'message' => 'Your booking is currently being processed. Please check your bookings tab in a moment.'
                ], 429);
            }

            try {
                $existingTransaction = Transaction::where('payment_reference', $paystackReference)->first();

                if ($existingTransaction) {
                    Log::info("Transaction already exists for reference: $paystackReference. Returning existing booking.");

                    // Find the associated inspection
                    $existingInspection = Inspection::where('transaction_id', $existingTransaction->id)->first();

                    if ($existingInspection) {
                        return response()->json([
                            'message' => 'Booking finalized successfully.',
                            'transaction' => $existingTransaction,
                            'inspection' => $existingInspection,
                        ], 201);
                    }

                    // Edge case: Transaction exists but no inspection (shouldn't happen, but handle it)
                    Log::warning("Transaction exists but no inspection found for reference: $paystackReference");
                    return response()->json([
                        'message' => 'Transaction exists but booking incomplete. Please contact support.',
                        'transaction' => $existingTransaction,
                    ], 400);
                }

                // 3. Create Transaction and Inspection atomically
                $result = DB::transaction(function () use ($user, $agentId, $propertyId, $inspectionDate, $inspectionTime, $bookingFee, $platformFee, $paymentMethod, $paystackReference, $paystackData) {
                    $agent = DB::table('cribs_agents')->where('agent_id', $agentId)->first();

                    if (!$agent) {
                        Log::error("Agent not found during booking finalization. Agent ID: $agentId");
                        throw new \Exception("Agent with ID $agentId not found.");
                    }

                    // Create Transaction Record with escrow status pending
                    // Store booking fee (agent's portion) not total with platform fee
                    $transaction = Transaction::create([
                        'payer_id' => $user->user_id, // Changed: use user_id (bigint business ID)
                        'payee_id' => $agent->agent_id, // Use agent_id (900001) not id (1)
                        'amount' => $bookingFee, // Agent's booking fee only
                        'currency' => $paystackData['currency'] ?? 'NGN',
                        'payment_reference' => $paystackReference,
                        'gateway' => 'paystack',
                        'channel' => $paystackData['channel'] ?? $paymentMethod,
                        'status' => $paystackData['status'] ?? 'success',
                        'escrow_status' => 1, // Pending in escrow
                    ]);

                    // Create Inspection Record with booking fee only (not platform fee)
                    $inspection = Inspection::create([
                        'user_id' => $user->user_id, // Changed: use user_id (bigint business ID)
                        'agent_id' => $agent->agent_id, // Use agent_id (900001) not id (1)
                        'property_id' => $propertyId,
                        'transaction_id' => $transaction->id,
                        'inspection_date' => $inspectionDate,
                        'inspection_time' => $inspectionTime,
                        'status' => 'scheduled',
                        'amount' => $bookingFee, // Agent's booking fee only
                        'payment_status' => 'paid',
                        'payment_method' => $paymentMethod,
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
                    $escrowReference = 'ESC_HOLD_' . uniqid() . '_' . time();
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
                        'description' => 'Inspection fee held in escrow - awaiting completion',
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

                    // Log Platform Fee (already extracted from metadata outside closure)
                    if ($platformFee > 0) {
                        DB::table('platform_fee_logs')->insert([
                            'transaction_reference' => $paystackReference,
                            'source_app' => 'user_app',
                            'user_id' => $user->user_id,
                            'amount' => $platformFee,
                            'description' => 'Platform fee for Inspection Booking',
                            'created_at' => now(),
                        ]);
                    }

                    return [
                        'transaction' => $transaction,
                        'inspection' => $inspection,
                        'agent' => $agent,
                        'user' => $user,
                        'platform_fee' => $platformFee,
                        'paystack_reference' => $paystackReference,
                        'escrow_amount' => $bookingFee,
                    ];
                });

                // Extract data from transaction result
                $transaction = $result['transaction'];
                $inspection = $result['inspection'];
                $agent = $result['agent'];
                $user = $result['user'];
                $platformFee = $result['platform_fee'];
                $paystackReference = $result['paystack_reference'];

                // Send notifications to user
                $agentName = "{$agent->first_name} {$agent->last_name}";

                // 1. Booking Confirmation to User
                \App\Helpers\NotificationHelper::sendUserNotification(
                    $user->user_id,
                    'booking_confirmed',
                    'Booking Confirmed',
                    "Your inspection booking with {$agentName} has been confirmed for {$inspectionDate} at {$inspectionTime}.",
                    [
                        'inspection_id' => $inspection->id,
                        'agent_id' => $agent->agent_id,
                        'agent_name' => $agentName,
                        'property_id' => $propertyId,
                        'date' => $inspectionDate,
                        'time' => $inspectionTime,
                    ]
                );

                // 2. Payment Successful to User
                \App\Helpers\NotificationHelper::sendUserNotification(
                    $user->user_id,
                    'payment_successful',
                    'Payment Successful',
                    "Your payment of ₦" . number_format($amount, 2) . " has been processed successfully.",
                    [
                        'transaction_id' => $transaction->id,
                        'amount' => $amount,
                        'reference' => $paystackReference,
                    ]
                );

                // 3. New Booking Request to Agent
                $userName = "{$user->first_name} {$user->last_name}";
                \App\Helpers\NotificationHelper::sendAgentNotification(
                    $agent->agent_id,
                    'new_booking_request',
                    'New Booking Request',
                    "{$userName} has booked an inspection for {$inspectionDate} at {$inspectionTime}.",
                    [
                        'inspection_id' => $inspection->id,
                        'user_id' => $user->user_id,
                        'user_name' => $userName,
                        'property_id' => $propertyId,
                        'date' => $inspectionDate,
                        'time' => $inspectionTime,
                        'amount' => $amount,
                    ]
                );

                // 4. Pending Income Notification to Agent
                \App\Helpers\NotificationHelper::sendAgentNotification(
                    $agent->agent_id,
                    'pending_income',
                    'Pending Income',
                    "₦" . number_format($amount, 2) . " is being held for you. Complete the inspection to receive payment.",
                    [
                        'inspection_id' => $inspection->id,
                        'amount' => $amount,
                        'status' => 'pending',
                    ]
                );

                return response()->json([
                    'message' => 'Booking finalized successfully.',
                    'transaction' => $transaction,
                    'inspection' => $inspection,
                ], 201);
            } finally {
                $lock->release();
            }
        } catch (\Exception $e) {
            Log::error('Booking Finalization Exception: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while finalizing your booking. Please try again later.'
            ], 500);
        }
    }
}
