<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AgentPlan;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AgentSubscriptionController extends Controller
{
    // List all available plans
    public function index()
    {
        try {
            $plans = AgentPlan::orderBy('price', 'asc')->get();
            return response()->json([
                'success' => true,
                'data' => $plans
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch subscription plans: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading subscription plans. Please try again later.'
            ], 500);
        }
    }

    // Get current subscription details
    public function current()
    {
        try {
            $agent = Auth::user();
            // The agent app uses cribs_agents table, which has agent_id column
            $agentId = $agent->agent_id;

            Log::info('Checking subscription for agent_id: ' . $agentId . ' (id: ' . $agent->id . ')');

            $currentSubscription = DB::table('paid_subscribers')
                ->join('agent_plans', 'paid_subscribers.plan_id', '=', 'agent_plans.plan_id')
                ->where('paid_subscribers.agent_id', $agentId)
                ->where('paid_subscribers.status', 'Active')
                ->select(
                    'paid_subscribers.*',
                    'agent_plans.name as plan_name',
                    'agent_plans.property_limit',
                    'agent_plans.description as plan_description'
                )
                ->orderBy('paid_subscribers.end_date', 'desc')
                ->first();

            Log::info('Subscription result: ' . ($currentSubscription ? json_encode($currentSubscription) : 'null'));

            if (!$currentSubscription) {
                return response()->json([
                    'success' => false,
                    'message' => 'No active subscription found.',
                    'agent_id' => $agentId
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => $currentSubscription
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch current subscription: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving your subscription details. Please try again later.'
            ], 500);
        }
    }

    // Get subscription history
    public function history()
    {
        try {
            $agentId = Auth::user()->agent_id;

            $history = DB::table('paid_subscribers')
                ->join('agent_plans', 'paid_subscribers.plan_id', '=', 'agent_plans.plan_id')
                ->where('paid_subscribers.agent_id', $agentId)
                ->select(
                    'paid_subscribers.*',
                    'agent_plans.name as plan_name',
                    'agent_plans.property_limit'
                )
                ->orderBy('paid_subscribers.created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $history
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch subscription history: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving your subscription history. Please try again later.'
            ], 500);
        }
    }

    // Initialize Subscription Payment
    // Initialize Subscription Payment
    public function initializeSubscription(Request $request)
    {
        $request->validate([
            'plan_id' => 'required|exists:agent_plans,plan_id',
        ]);

        $agent = Auth::user();
        $plan = AgentPlan::findOrFail($request->plan_id);

        // Fetch platform fee
        $platformFee = DB::table('platform_settings')
            ->where('key_name', 'platform_fee')
            ->value('value') ?? 700.00; // Default to 700 if not set

        $totalAmount = $plan->price + $platformFee;
        $amountInKobo = $totalAmount * 100;

        $reference = 'sub_' . uniqid() . '_' . time();

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . env('PAYSTACK_SECRET_KEY'),
                'Content-Type' => 'application/json',
            ])->post('https://api.paystack.co/transaction/initialize', [
                        'email' => $agent->email,
                        'amount' => $amountInKobo,
                        'reference' => $reference,
                        'callback_url' => 'https://standard.paystack.co/close', // Standard close URL if using WebView
                        'metadata' => [
                            'agent_id' => $agent->agent_id, // agent_id from cribs_agents table
                            'plan_id' => $plan->plan_id,
                            'type' => 'agent_subscription',
                            'platform_fee' => $platformFee // Track fee
                        ],
                    ]);

            if ($response->successful()) {
                return response()->json([
                    'success' => true,
                    'data' => $response->json()['data']
                ]);
            } else {
                Log::error('Paystack Init Error: ' . $response->body());
                return response()->json([
                    'success' => false,
                    'message' => 'An error occurred while initializing the payment. Please try again later.'
                ], 400);
            }
        } catch (\Exception $e) {
            Log::error('Subscription Init Exception: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while initializing your subscription. Please try again later.'
            ], 500);
        }
    }

    // Verify and Finalize Subscription
    public function verifySubscription(Request $request)
    {
        $request->validate([
            'reference' => 'required|string',
        ]);

        $reference = $request->reference;

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

            // Validate metadata
            if (!isset($metadata['type']) || $metadata['type'] !== 'agent_subscription') {
                // Might be a different type of transaction
            }

            $agentId = $metadata['agent_id'];
            $planId = $metadata['plan_id'];
            $platformFee = $metadata['platform_fee'] ?? 0;

            $plan = AgentPlan::findOrFail($planId);

            // 2. Check if already processed
            $existing = DB::table('paid_subscribers')
                ->where('paystack_reference', $reference)
                ->first();

            if ($existing) {
                return response()->json(['success' => true, 'message' => 'Subscription already active']);
            }

            // 3. Mark previous subscriptions as Expired
            DB::table('paid_subscribers')
                ->where('agent_id', $agentId)
                ->where('status', 'Active')
                ->update(['status' => 'Expired']);

            // 4. Create new subscription
            DB::table('paid_subscribers')->insert([
                'agent_id' => $agentId,
                'plan_id' => $planId,
                'start_date' => now(),
                'end_date' => now()->addDays(30), // Monthly sub
                'upload_count' => 0,
                'amount_paid' => $plan->price, // Storing plan price, platform fee tracked separately
                'payment_method' => 'Paystack',
                'paystack_reference' => $reference,
                'status' => 'Active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // 5. Log Platform Fee
            if ($platformFee > 0) {
                DB::table('platform_fee_logs')->insert([
                    'transaction_reference' => $reference,
                    'source_app' => 'agent_app',
                    'user_id' => $agentId,
                    'amount' => $platformFee,
                    'description' => "Platform fee for Agent Subscription (Plan: {$plan->name})",
                    'created_at' => now(),
                ]);
            }

            // 6. Send Email and Notification
            $agentUser = \App\Models\Agent::find($agentId); // Assuming Agent model exists and links to auth user logic
            // Fallback since Auth::user is the logged in user, ensure we have email
            $email = $agentUser ? $agentUser->email : Auth::user()->email;
            $name = $agentUser ? $agentUser->first_name : 'Agent';

            $subData = [
                'name' => $name,
                'plan_name' => $plan->name,
                'amount' => $plan->price,
                'start_date' => now()->format('Y-m-d'),
                'end_date' => now()->addDays(30)->format('Y-m-d'),
                'reference' => $reference,
            ];

            try {
                \Illuminate\Support\Facades\Mail::to($email)->send(new \App\Mail\SubscriptionActivatedMail($subData));
            } catch (\Exception $e) {
                Log::error('Mail Error: ' . $e->getMessage());
            }

            // Send Push Notification (assuming NotificationService exists as per context)
            // \App\Services\NotificationService::send($agentId, 'Subscription Activated', 'Your ' . $plan->name . ' plan is now active.', ['type' => 'subscription']); 
            // Or using DB notification
            DB::table('notifications')->insert([
                'receiver_id' => $agentId,
                'receiver_type' => 'agent',
                'type' => 'subscription',
                'title' => 'Subscription Activated',
                'body' => "Your {$plan->name} plan is now active.",
                'is_read' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);


            return response()->json(['success' => true, 'message' => 'Subscription activated successfully']);

        } catch (\Exception $e) {
            Log::error('Subscription Verify Exception: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while verifying your subscription. Please contact support if your payment was successful.'
            ], 500);
        }
    }

    // Subscribe using wallet balance
    public function subscribeWithWallet(Request $request)
    {
        $request->validate([
            'plan_id' => 'required|exists:agent_plans,plan_id',
        ]);

        $agent = Auth::user();
        $plan = AgentPlan::findOrFail($request->plan_id);

        // Fetch platform fee
        $platformFee = DB::table('platform_settings')
            ->where('key_name', 'platform_fee')
            ->value('value') ?? 700.00;

        $totalAmount = $plan->price + $platformFee;

        // Get or create wallet
        $wallet = \App\Models\Wallet::getOrCreate($agent->agent_id, 'agent');

        // Check if sufficient balance
        if ($wallet->available_balance < $totalAmount) {
            return response()->json([
                'success' => false,
                'message' => 'Insufficient wallet balance',
                'data' => [
                    'required_amount' => $totalAmount,
                    'available_balance' => $wallet->available_balance,
                    'shortfall' => $totalAmount - $wallet->available_balance,
                ]
            ], 400);
        }

        try {
            DB::beginTransaction();

            // Generate reference
            $reference = 'wallet_sub_' . uniqid() . '_' . time();

            // 1. Debit wallet
            $wallet->debit($totalAmount);

            // 2. Mark previous subscriptions as Expired
            DB::table('paid_subscribers')
                ->where('agent_id', $agent->agent_id)
                ->where('status', 'Active')
                ->update(['status' => 'Expired']);

            // 3. Create new subscription
            DB::table('paid_subscribers')->insert([
                'agent_id' => $agent->agent_id,
                'plan_id' => $plan->plan_id,
                'start_date' => now(),
                'end_date' => now()->addDays(30),
                'upload_count' => 0,
                'amount_paid' => $plan->price,
                'payment_method' => 'Wallet',
                'paystack_reference' => $reference,
                'status' => 'Active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // 4. Create wallet transaction record
            // 4. Create wallet transaction record
            \App\Models\WalletTransaction::create([
                'wallet_id' => $wallet->id,
                'user_id' => $wallet->user_id,
                'user_type' => $wallet->user_type,
                'transaction_type' => 'subscription',
                'amount' => $totalAmount,
                'fee' => $platformFee,
                'net_amount' => $totalAmount,
                'balance_before' => $wallet->available_balance + $totalAmount,
                'balance_after' => $wallet->available_balance,
                'currency' => 'NGN',
                'reference' => $reference,
                'paystack_reference' => $reference,
                'status' => 'success',
                'description' => "Subscription to {$plan->name} plan",
            ]);

            // 5. Log Platform Fee
            if ($platformFee > 0) {
                DB::table('platform_fee_logs')->insert([
                    'transaction_reference' => $reference,
                    'source_app' => 'agent_app',
                    'user_id' => $agent->agent_id,
                    'amount' => $platformFee,
                    'description' => "Platform fee for Agent Subscription (Plan: {$plan->name}) via Wallet",
                    'created_at' => now(),
                ]);
            }

            // 6. Send Email and Notification
            $subData = [
                'name' => $agent->first_name ?? 'Agent',
                'plan_name' => $plan->name,
                'amount' => $plan->price,
                'start_date' => now()->format('Y-m-d'),
                'end_date' => now()->addDays(30)->format('Y-m-d'),
                'reference' => $reference,
            ];

            try {
                \Illuminate\Support\Facades\Mail::to($agent->email)->send(new \App\Mail\SubscriptionActivatedMail($subData));
            } catch (\Exception $e) {
                Log::error('Wallet Mail Error: ' . $e->getMessage());
            }

            DB::table('notifications')->insert([
                'receiver_id' => $agent->agent_id,
                'receiver_type' => 'agent',
                'type' => 'subscription',
                'title' => 'Subscription Activated',
                'body' => "Your {$plan->name} plan is now active via Wallet payment.",
                'is_read' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Subscription activated successfully',
                'data' => [
                    'plan_name' => $plan->name,
                    'amount_paid' => $totalAmount,
                    'new_balance' => $wallet->available_balance,
                ]
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Wallet Subscription Exception: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while processing your subscription via wallet. Please try again later.'
            ], 500);
        }
    }
}
