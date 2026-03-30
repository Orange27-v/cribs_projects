<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Models\TransferRecipient;
use App\Models\WithdrawalRequest;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Cache;
use App\Helpers\NotificationHelper;
use App\Mail\WithdrawalInitiatedMail;
use App\Mail\BankAccountAddedMail;

class AgentWithdrawalController extends Controller
{
    private string $paystackSecretKey;
    private string $paystackBaseUrl = 'https://api.paystack.co';

    // Constants for withdrawal limits
    private const MIN_NET_WITHDRAWAL = 1000;
    private const MAX_WITHDRAWAL = 10000000;
    private const CACHE_TTL_FEE = 3600; // 1 hour

    public function __construct()
    {
        $this->paystackSecretKey = config('services.paystack.secret_key', env('PAYSTACK_SECRET_KEY'));
    }

    /**
     * Get list of Nigerian banks from Paystack
     */
    public function getBanks(Request $request): JsonResponse
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->paystackSecretKey,
            ])->get($this->paystackBaseUrl . '/bank', [
                        'country' => 'nigeria',
                        'perPage' => 100,
                    ]);

            if ($response->successful()) {
                $banks = $response->json()['data'] ?? [];

                // Format banks for frontend
                $formattedBanks = collect($banks)->map(function ($bank) {
                    return [
                        'code' => $bank['code'],
                        'name' => $bank['name'],
                        'slug' => $bank['slug'] ?? null,
                    ];
                })->sortBy('name')->values();

                return response()->json([
                    'success' => true,
                    'data' => ['banks' => $formattedBanks]
                ], 200);
            }

            Log::error('Failed to fetch banks. Paystack Response: ' . $response->body());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading the list of banks. Please try again later.'
            ], 500);

        } catch (\Exception $e) {
            Log::error('Failed to fetch banks: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while fetching the list of banks. Please try again later.'
            ], 500);
        }
    }

    /**
     * Verify bank account using Paystack
     */
    public function verifyBankAccount(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'account_number' => 'required|string|size:10',
                'bank_code' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->paystackSecretKey,
            ])->get($this->paystackBaseUrl . '/bank/resolve', [
                        'account_number' => $request->account_number,
                        'bank_code' => $request->bank_code,
                    ]);

            if ($response->successful()) {
                $data = $response->json()['data'] ?? [];

                return response()->json([
                    'success' => true,
                    'message' => 'Account verified successfully',
                    'data' => [
                        'account_number' => $data['account_number'] ?? $request->account_number,
                        'account_name' => $data['account_name'] ?? '',
                        'bank_id' => $data['bank_id'] ?? null,
                    ]
                ], 200);
            }

            $errorMessage = $response->json()['message'] ?? 'Account verification failed';
            return response()->json([
                'success' => false,
                'message' => $errorMessage
            ], 400);

        } catch (\Exception $e) {
            Log::error('Bank verification failed: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred during account verification. Please verify the account details and try again.'
            ], 500);
        }
    }

    /**
     * Save bank account as Paystack transfer recipient
     */
    public function saveBankAccount(Request $request): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $validator = Validator::make($request->all(), [
                'account_number' => 'required|string|size:10',
                'bank_code' => 'required|string',
                'bank_name' => 'required|string|max:100',
                'account_name' => 'required|string|max:255',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Check if this account already exists for this agent
            $existing = TransferRecipient::where('user_id', $agent->agent_id)
                ->where('user_type', 'agent')
                ->where('bank_code', $request->bank_code)
                ->where('account_number', $request->account_number)
                ->where('is_active', true)
                ->first();

            if ($existing) {
                return response()->json([
                    'success' => false,
                    'message' => 'This bank account is already saved'
                ], 409);
            }

            // Create recipient on Paystack
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->paystackSecretKey,
                'Content-Type' => 'application/json',
            ])->post($this->paystackBaseUrl . '/transferrecipient', [
                        'type' => 'nuban',
                        'name' => $request->account_name,
                        'account_number' => $request->account_number,
                        'bank_code' => $request->bank_code,
                        'currency' => 'NGN',
                    ]);

            if (!$response->successful()) {
                $errorMessage = $response->json()['message'] ?? 'Failed to create recipient';
                Log::error('Paystack recipient creation failed: ' . $errorMessage);
                return response()->json([
                    'success' => false,
                    'message' => $errorMessage
                ], 400);
            }

            $recipientData = $response->json()['data'] ?? [];
            $recipientCode = $recipientData['recipient_code'] ?? null;

            if (!$recipientCode) {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to get recipient code from Paystack'
                ], 500);
            }

            // Check if this is the first bank account (make it default)
            $isDefault = !TransferRecipient::where('user_id', $agent->agent_id)
                ->where('user_type', 'agent')
                ->where('is_active', true)
                ->exists();

            // Save to database
            $recipient = TransferRecipient::create([
                'user_id' => $agent->agent_id,
                'user_type' => 'agent',
                'recipient_code' => $recipientCode,
                'bank_code' => $request->bank_code,
                'bank_name' => $request->bank_name,
                'account_number' => $request->account_number,
                'account_name' => $request->account_name,
                'is_default' => $isDefault,
                'is_active' => true,
            ]);

            // Send notification and email
            try {
                $accountData = [
                    'userName' => $agent->first_name ?: 'Agent',
                    'bankName' => $recipient->bank_name,
                    'accountNumber' => $recipient->account_number,
                    'accountName' => $recipient->account_name,
                ];

                NotificationHelper::sendAgentNotification(
                    $agent->agent_id,
                    'bank_account_added',
                    'Bank Account Linked',
                    "A new bank account ({$recipient->bank_name}) has been successfully linked to your wallet."
                );

                Mail::to($agent->email)->send(new BankAccountAddedMail($accountData));
            } catch (\Exception $e) {
                Log::error('Bank account notification failed: ' . $e->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => 'Bank account saved successfully',
                'data' => [
                    'bank_account' => [
                        'id' => $recipient->id,
                        'bank_name' => $recipient->bank_name,
                        'account_number' => $recipient->masked_account_number,
                        'account_name' => $recipient->account_name,
                        'is_default' => $recipient->is_default,
                    ]
                ]
            ], 201);

        } catch (\Exception $e) {
            Log::error('Save bank account failed: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while saving your bank account. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get saved bank accounts for agent
     */
    public function getBankAccounts(Request $request): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $recipients = TransferRecipient::getForUser($agent->agent_id, 'agent');

            $formattedAccounts = $recipients->map(function ($r) {
                return [
                    'id' => $r->id,
                    'bank_name' => $r->bank_name,
                    'bank_code' => $r->bank_code,
                    'account_number' => $r->masked_account_number,
                    'account_name' => $r->account_name,
                    'is_default' => $r->is_default,
                    'created_at' => $r->created_at->toIso8601String(),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => ['bank_accounts' => $formattedAccounts]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch bank accounts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while fetching your bank accounts. Please try again later.'
            ], 500);
        }
    }

    /**
     * Delete a saved bank account
     */
    public function deleteBankAccount(Request $request, int $id): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $recipient = TransferRecipient::where('id', $id)
                ->where('user_id', $agent->agent_id)
                ->where('user_type', 'agent')
                ->where('is_active', true)
                ->first();

            if (!$recipient) {
                return response()->json([
                    'success' => false,
                    'message' => 'Bank account not found'
                ], 404);
            }

            // Soft delete by deactivating
            $recipient->deactivate();

            // If this was the default, make another one default
            if ($recipient->is_default) {
                $newDefault = TransferRecipient::where('user_id', $agent->agent_id)
                    ->where('user_type', 'agent')
                    ->where('is_active', true)
                    ->first();

                if ($newDefault) {
                    $newDefault->setAsDefault();
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Bank account removed successfully'
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to remove bank account: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while removing the bank account. Please try again later.'
            ], 500);
        }
    }

    /**
     * Initiate a withdrawal
     */
    /**
     * Initiate a withdrawal
     */
    public function withdraw(Request $request): JsonResponse
    {
        $agent = Auth::guard('agent')->user();
        $withdrawalRequest = null;
        $recipient = null;

        if (!$agent) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 401);
        }

        // Check verification status
        if (($agent->nin_verification ?? 0) !== 1 || ($agent->bvn_verification ?? 0) !== 1) {
            return response()->json([
                'success' => false,
                'message' => 'Please verify your NIN and BVN to complete withdrawal'
            ], 403);
        }

        // Atomic Lock to prevent double withdrawal (Race Condition)
        $lock = Cache::lock('withdrawal_agent_' . $agent->agent_id, 10); // 10 seconds lock

        if (!$lock->get()) {
            return response()->json([
                'success' => false,
                'message' => 'A withdrawal is already processing. Please wait.'
            ], 429);
        }

        try {
            $validator = Validator::make($request->all(), [
                'amount' => 'required|numeric|min:100|max:' . self::MAX_WITHDRAWAL,
                'recipient_id' => 'required|integer',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $amount = (float) $request->amount;

            // Get wallet
            $wallet = Wallet::getOrCreate($agent->agent_id, 'agent');

            // Check balance
            if (!$wallet->canWithdraw($amount)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Insufficient balance'
                ], 400);
            }

            // Get recipient
            $recipient = TransferRecipient::where('id', $request->recipient_id)
                ->where('user_id', $agent->agent_id)
                ->where('user_type', 'agent')
                ->where('is_active', true)
                ->first();

            if (!$recipient) {
                return response()->json([
                    'success' => false,
                    'message' => 'Bank account not found'
                ], 404);
            }

            // Calculate fee dynamically from platform settings (Cached)
            $platformFee = Cache::remember('platform_fee', self::CACHE_TTL_FEE, function () {
                return DB::table('platform_settings')
                    ->where('key_name', 'platform_fee')
                    ->value('value') ?? 0.00;
            });

            $netAmount = $amount - $platformFee;

            if ($netAmount < self::MIN_NET_WITHDRAWAL) {
                return response()->json([
                    'success' => false,
                    'message' => 'Net withdrawal amount must be at least ₦' . number_format(self::MIN_NET_WITHDRAWAL)
                ], 400);
            }

            // Start transaction
            DB::beginTransaction();

            try {
                // Deduct from wallet
                $wallet->debit($amount);
                $wallet->recordWithdrawal($amount);

                // Create wallet transaction
                $walletTransaction = WalletTransaction::createWithdrawal(
                    $wallet,
                    $amount,
                    $platformFee,
                    $recipient->getRecipientCode(),
                    'Withdrawal to ' . $recipient->bank_name . ' - ' . $recipient->masked_account_number
                );

                // Create withdrawal request
                $withdrawalRequest = WithdrawalRequest::create([
                    'user_id' => $agent->agent_id,
                    'user_type' => 'agent',
                    'wallet_transaction_id' => $walletTransaction->id,
                    'recipient_id' => $recipient->id,
                    'amount' => $amount,
                    'fee' => $platformFee,
                    'net_amount' => $netAmount,
                    'currency' => 'NGN',
                    'reference' => WithdrawalRequest::generateReference(),
                    'status' => WithdrawalRequest::STATUS_PENDING,
                ]);

                // Initiate Paystack transfer
                $paystackResponse = Http::withHeaders([
                    'Authorization' => 'Bearer ' . $this->paystackSecretKey,
                    'Content-Type' => 'application/json',
                ])->post($this->paystackBaseUrl . '/transfer', [
                            'source' => 'balance',
                            'amount' => (int) ($netAmount * 100), // Convert to kobo
                            'recipient' => $recipient->getRecipientCode(),
                            'reason' => 'Agent withdrawal - ' . $withdrawalRequest->reference,
                            'reference' => $withdrawalRequest->reference,
                        ]);

                if (!$paystackResponse->successful()) {
                    throw new \Exception($paystackResponse->json()['message'] ?? 'Transfer initiation failed');
                }

                $transferData = $paystackResponse->json()['data'] ?? [];
                $transferCode = $transferData['transfer_code'] ?? null;

                // Update withdrawal request with Paystack data
                $withdrawalRequest->markProcessing($transferCode, $withdrawalRequest->reference);

                DB::commit();

                return response()->json([
                    'success' => true,
                    'message' => 'Withdrawal initiated successfully',
                    'data' => [
                        'withdrawal' => [
                            'id' => $withdrawalRequest->id,
                            'amount' => (float) $amount,
                            'fee' => (float) $platformFee,
                            'net_amount' => (float) $netAmount,
                            'status' => $withdrawalRequest->status,
                            'reference' => $withdrawalRequest->reference,
                            'bank_name' => $recipient->bank_name,
                            'account_number' => $recipient->masked_account_number,
                        ],
                        'new_balance' => (float) $wallet->available_balance,
                    ]
                ], 200);

            } catch (\Exception $e) {
                DB::rollBack();
                Log::error('Withdrawal failed: ' . $e->getMessage());
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('Withdrawal error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while processing your withdrawal. Please try again later.'
            ], 500);
        } finally {
            // Send notification and email outside transaction
            if ($withdrawalRequest instanceof WithdrawalRequest && $recipient instanceof TransferRecipient && $withdrawalRequest->status === WithdrawalRequest::STATUS_PROCESSING) {
                try {
                    $withdrawalData = [
                        'userName' => $agent->first_name ?: 'Agent',
                        'grossAmount' => (float) $amount,
                        'platformFee' => (float) $platformFee,
                        'netAmount' => (float) $netAmount,
                        'bankName' => $recipient->bank_name,
                        'accountNumber' => $recipient->masked_account_number,
                        'reference' => $withdrawalRequest->reference,
                    ];

                    NotificationHelper::sendAgentNotification(
                        $agent->agent_id,
                        'withdrawal_initiated',
                        'Withdrawal Initiated',
                        "You have initiated a withdrawal of ₦" . number_format($netAmount, 2) . " to your {$recipient->bank_name} account."
                    );

                    Mail::to($agent->email)->send(new WithdrawalInitiatedMail($withdrawalData));
                } catch (\Exception $e) {
                    Log::error('Withdrawal notification failed: ' . $e->getMessage());
                }
            }

            $lock?->release();
        }
    }

    /**
     * Get withdrawal history
     */
    public function getWithdrawals(Request $request): JsonResponse
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $perPage = $request->get('per_page', 20);

            $withdrawals = WithdrawalRequest::where('user_id', $agent->agent_id)
                ->where('user_type', 'agent')
                ->with('recipient')
                ->orderBy('created_at', 'desc')
                ->paginate($perPage);

            $formattedWithdrawals = collect($withdrawals->items())->map(function ($w) {
                return [
                    'id' => $w->id,
                    'amount' => (float) $w->amount,
                    'fee' => (float) $w->fee,
                    'net_amount' => (float) $w->net_amount,
                    'status' => $w->status,
                    'reference' => $w->reference,
                    'bank_name' => $w->recipient->bank_name ?? 'Unknown',
                    'account_number' => $w->recipient->masked_account_number ?? '****',
                    'failure_reason' => $w->failure_reason,
                    'processed_at' => $w->processed_at?->toIso8601String(),
                    'created_at' => $w->created_at->toIso8601String(),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'withdrawals' => $formattedWithdrawals,
                    'pagination' => [
                        'current_page' => $withdrawals->currentPage(),
                        'last_page' => $withdrawals->lastPage(),
                        'per_page' => $withdrawals->perPage(),
                        'total' => $withdrawals->total(),
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch withdrawals: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while fetching your withdrawal history. Please try again later.'
            ], 500);
        }
    }
}
