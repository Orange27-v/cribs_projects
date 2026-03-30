<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Mail;
use App\Helpers\NotificationHelper;
use App\Mail\PaymentConfirmationMail;

class AgentWalletController extends Controller
{
    /**
     * Get agent's wallet balance
     */
    public function getWallet(Request $request): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Get or create wallet for agent
            $wallet = Wallet::getOrCreate($agent->agent_id, 'agent');

            return response()->json([
                'success' => true,
                'message' => 'Wallet retrieved successfully',
                'data' => [
                    'wallet' => [
                        'id' => $wallet->id,
                        'available_balance' => (float) $wallet->available_balance,
                        'pending_balance' => (float) $wallet->pending_balance,
                        'total_balance' => (float) $wallet->total_balance,
                        'total_earned' => (float) $wallet->total_earned,
                        'total_withdrawn' => (float) $wallet->total_withdrawn,
                        'currency' => $wallet->currency,
                    ],
                    'agent' => [
                        'nin_verification' => (int) $agent->nin_verification,
                        'bvn_verification' => (int) $agent->bvn_verification,
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to retrieve wallet: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving your wallet information. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get agent's wallet transaction history
     */
    public function getTransactions(Request $request): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Get wallet
            $wallet = Wallet::getOrCreate($agent->agent_id, 'agent');

            // Get transactions with pagination
            $perPage = $request->get('per_page', 20);
            $type = $request->get('type'); // Filter by transaction type

            $query = WalletTransaction::where('wallet_id', $wallet->id)
                ->orderBy('created_at', 'desc');

            // Apply type filter if provided
            if (
                $type && in_array($type, [
                    WalletTransaction::TYPE_DEPOSIT,
                    WalletTransaction::TYPE_WITHDRAWAL,
                    WalletTransaction::TYPE_REFUND,
                    WalletTransaction::TYPE_ESCROW_RELEASE,
                    WalletTransaction::TYPE_ESCROW_HOLD,
                    WalletTransaction::TYPE_PLATFORM_FEE,
                ])
            ) {
                $query->where('transaction_type', $type);
            }

            $transactions = $query->paginate($perPage);

            // Format transactions for response
            $formattedTransactions = collect($transactions->items())->map(function ($tx) {
                return [
                    'id' => $tx->id,
                    'type' => $tx->transaction_type,
                    'amount' => (float) $tx->amount,
                    'fee' => (float) $tx->fee,
                    'net_amount' => (float) $tx->net_amount,
                    'balance_before' => (float) $tx->balance_before,
                    'balance_after' => (float) $tx->balance_after,
                    'currency' => $tx->currency,
                    'reference' => $tx->reference,
                    'status' => $tx->status,
                    'description' => $tx->description,
                    'is_credit' => $tx->isCredit(),
                    'created_at' => $tx->created_at->toIso8601String(),
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Transactions retrieved successfully',
                'data' => [
                    'transactions' => $formattedTransactions,
                    'pagination' => [
                        'current_page' => $transactions->currentPage(),
                        'last_page' => $transactions->lastPage(),
                        'per_page' => $transactions->perPage(),
                        'total' => $transactions->total(),
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to retrieve transactions: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving your transactions. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get single transaction details
     */
    public function getTransactionDetails(Request $request, $id): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Get wallet
            $wallet = Wallet::getOrCreate($agent->agent_id, 'agent');

            // Find transaction
            $tx = WalletTransaction::where('wallet_id', $wallet->id)
                ->where('id', $id)
                ->first();

            if (!$tx) {
                return response()->json([
                    'success' => false,
                    'message' => 'Transaction not found'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Transaction details retrieved successfully',
                'data' => [
                    'id' => $tx->id,
                    'type' => $tx->transaction_type,
                    'amount' => (float) $tx->amount,
                    'fee' => (float) $tx->fee,
                    'net_amount' => (float) $tx->net_amount,
                    'balance_before' => (float) $tx->balance_before,
                    'balance_after' => (float) $tx->balance_after,
                    'currency' => $tx->currency,
                    'reference' => $tx->reference,
                    'paystack_reference' => $tx->paystack_reference,
                    'status' => $tx->status,
                    'description' => $tx->description,
                    'is_credit' => $tx->isCredit(),
                    'created_at' => $tx->created_at->toIso8601String(),
                    'updated_at' => $tx->updated_at->toIso8601String(),
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to retrieve transaction details: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving transaction details. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get wallet summary stats
     */
    public function getSummary(Request $request): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $wallet = Wallet::getOrCreate($agent->agent_id, 'agent');

            // Get recent transaction counts
            $last30Days = now()->subDays(30);

            $depositCount = WalletTransaction::where('wallet_id', $wallet->id)
                ->where('transaction_type', WalletTransaction::TYPE_DEPOSIT)
                ->where('status', WalletTransaction::STATUS_SUCCESS)
                ->where('created_at', '>=', $last30Days)
                ->count();

            $withdrawalCount = WalletTransaction::where('wallet_id', $wallet->id)
                ->where('transaction_type', WalletTransaction::TYPE_WITHDRAWAL)
                ->where('status', WalletTransaction::STATUS_SUCCESS)
                ->where('created_at', '>=', $last30Days)
                ->count();

            $earnedThisMonth = WalletTransaction::where('wallet_id', $wallet->id)
                ->whereIn('transaction_type', [
                    WalletTransaction::TYPE_DEPOSIT,
                    WalletTransaction::TYPE_ESCROW_RELEASE,
                ])
                ->where('status', WalletTransaction::STATUS_SUCCESS)
                ->where('created_at', '>=', $last30Days)
                ->sum('net_amount');

            $withdrawnThisMonth = WalletTransaction::where('wallet_id', $wallet->id)
                ->where('transaction_type', WalletTransaction::TYPE_WITHDRAWAL)
                ->where('status', WalletTransaction::STATUS_SUCCESS)
                ->where('created_at', '>=', $last30Days)
                ->sum('net_amount');

            return response()->json([
                'success' => true,
                'message' => 'Summary retrieved successfully',
                'data' => [
                    'available_balance' => (float) $wallet->available_balance,
                    'pending_balance' => (float) $wallet->pending_balance,
                    'total_earned' => (float) $wallet->total_earned,
                    'total_withdrawn' => (float) $wallet->total_withdrawn,
                    'earned_this_month' => (float) $earnedThisMonth,
                    'withdrawn_this_month' => (float) $withdrawnThisMonth,
                    'deposit_count_this_month' => $depositCount,
                    'withdrawal_count_this_month' => $withdrawalCount,
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to retrieve wallet summary: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving your wallet summary. Please try again later.'
            ], 500);
        }
    }

    /**
     * Initialize deposit transaction
     */
    public function initializeDeposit(Request $request): JsonResponse
    {
        $request->validate([
            'amount' => 'required|numeric',
        ]);

        try {
            $agent = Auth::guard('agent')->user();
            $amount = $request->amount;

            // Fetch current platform fee to validate net amount
            $platformFee = DB::table('platform_settings')
                ->where('key_name', 'platform_fee')
                ->value('value') ?? 0.00;

            if (($amount - $platformFee) < 1000) {
                return response()->json([
                    'success' => false,
                    'message' => 'Minimum net credit must be ₦1,000. Required deposit: ₦' . (1000 + $platformFee)
                ], 400);
            }

            $amountInKobo = $amount * 100;
            $reference = WalletTransaction::generateReference('DEP');

            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . env('PAYSTACK_SECRET_KEY'),
                'Content-Type' => 'application/json',
            ])->post('https://api.paystack.co/transaction/initialize', [
                        'email' => $agent->email,
                        'amount' => $amountInKobo,
                        'reference' => $reference,
                        'callback_url' => 'https://standard.paystack.co/close',
                        'metadata' => [
                            'agent_id' => $agent->agent_id,
                            'type' => 'wallet_deposit',
                            'wallet_amount' => $amount,
                        ],
                    ]);

            if ($response->successful()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Deposit initialized successfully',
                    'data' => $response->json()['data']
                ], 200);
            } else {
                Log::error('Paystack Deposit Init Error: ' . $response->body());
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to initialize deposit'
                ], 400);
            }

        } catch (\Exception $e) {
            Log::error('Deposit Init Exception: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while initializing your deposit. Please try again later.'
            ], 500);
        }
    }

    /**
     * Verify deposit transaction
     */
    public function verifyDeposit(Request $request): JsonResponse
    {
        $request->validate([
            'reference' => 'required|string',
        ]);

        $reference = $request->reference;

        $lockKey = 'verify_deposit_' . $reference;
        $lock = Cache::lock($lockKey, 15);

        if (!$lock->get()) {
            return response()->json(['success' => false, 'message' => 'Deposit is currently being verified. Please wait a moment.'], 429);
        }

        try {
            // 1. Verify with Paystack
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . env('PAYSTACK_SECRET_KEY'),
            ])->get("https://api.paystack.co/transaction/verify/$reference");

            if (!$response->successful() || $response->json('data.status') !== 'success') {
                return response()->json(['success' => false, 'message' => 'Payment verification failed'], 400);
            }

            $data = $response->json('data');
            $metadata = $data['metadata'];
            $agent = Auth::guard('agent')->user();

            // Validate metadata
            if (!isset($metadata['type']) || $metadata['type'] !== 'wallet_deposit') {
                return response()->json(['success' => false, 'message' => 'Invalid transaction type'], 400);
            }

            // 2. Check if already processed
            $existing = WalletTransaction::where('paystack_reference', $reference)->first();
            if ($existing) {
                return response()->json(['success' => true, 'message' => 'Transaction already processed']);
            }

            $grossAmount = $metadata['wallet_amount']; // Gross amount from Paystack
            $platformFee = DB::table('platform_settings')
                ->where('key_name', 'platform_fee')
                ->value('value') ?? 0.00;
            $netAmount = $grossAmount - $platformFee;

            // 3. Credit Wallet
            $wallet = Wallet::getOrCreate($agent->agent_id, 'agent');
            $wallet->credit($netAmount);

            // 4. Record Transaction
            WalletTransaction::createDeposit(
                $wallet,
                $grossAmount,
                $platformFee,
                'Wallet Deposit via Paystack',
                $reference
            );

            // 5. Log Platform Fee
            DB::table('platform_fee_logs')->insert([
                'transaction_reference' => $reference,
                'source_app' => 'agent_app',
                'user_id' => $agent->agent_id,
                'amount' => $platformFee,
                'description' => 'Platform fee for Wallet Deposit',
                'created_at' => now(),
            ]);

            // 6. Send Notification & Email to Agent
            try {
                $title = "Wallet Deposit Successful";
                $body = "Your wallet has been credited with ₦" . number_format($netAmount, 2) . " (Gross: ₦" . number_format($grossAmount, 2) . ", Fee: ₦" . number_format($platformFee, 2) . ")";

                NotificationHelper::sendAgentNotification(
                    $agent->agent_id,
                    'wallet_deposit',
                    $title,
                    $body,
                    [
                        'gross_amount' => $grossAmount,
                        'platform_fee' => $platformFee,
                        'net_amount' => $netAmount,
                        'reference' => $reference
                    ]
                );

                // Send Email
                $paymentData = [
                    'userName' => $agent->name ?? 'Agent',
                    'amount' => $netAmount,
                    'transactionId' => $reference,
                    'reference' => $reference,
                    'paymentMethod' => 'Card (Paystack)',
                    'paymentDate' => now()->format('Y-m-d H:i:s'),
                    'description' => "Wallet Deposit (Platform Fee: ₦" . number_format($platformFee, 2) . " deducted)"
                ];

                Mail::to($agent->email)->send(new PaymentConfirmationMail($paymentData));

            } catch (\Exception $e) {
                Log::error('Deposit Notification Error: ' . $e->getMessage());
                // Don't fail the request if notification fails
            }

            return response()->json([
                'success' => true,
                'message' => 'Wallet funded successfully',
                'data' => [
                    'new_balance' => $wallet->available_balance,
                    'gross_amount' => $grossAmount,
                    'platform_fee' => $platformFee,
                    'net_amount' => $netAmount
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Deposit Verify Exception: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while verifying your deposit. Please contact support if your payment was successful.'
            ], 500);
        } finally {
            $lock->release();
        }
    }
}
