<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AgentPlan;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Google\Client;
use Google\Service\AndroidPublisher;

class GoogleBillingController extends Controller
{
    /**
     * Map Google Product IDs to Database Plan IDs
     */
    protected $productMapping = [
        'cribs_agent_basic' => 1,
        'cribs_agent_standard' => 2,
        'cribs_agent_premium' => 3,
        // Add more mappings as configured in Google Play Console
    ];

    /**
     * Verify a Google Play Subscription Purchase
     */
    public function verifySubscription(Request $request)
    {
        $request->validate([
            'purchaseToken' => 'required|string',
            'productId' => 'required|string',
        ]);

        $purchaseToken = $request->purchaseToken;
        $productId = $request->productId;
        $agent = Auth::user();

        // Check mapping
        if (!isset($this->productMapping[$productId])) {
            Log::error("GoogleBilling: Unmapped productId: $productId");
            return response()->json([
                'success' => false,
                'message' => 'Invalid product identifier.'
            ], 400);
        }

        $planId = $this->productMapping[$productId];
        $plan = AgentPlan::find($planId);

        if (!$plan) {
            return response()->json([
                'success' => false,
                'message' => 'Linked plan not found in database.'
            ], 404);
        }

        // Check if already processed (Replay protection)
        $existing = DB::table('paid_subscribers')
            ->where('paystack_reference', $purchaseToken)
            ->first();

        if ($existing) {
            return response()->json([
                'success' => true,
                'message' => 'Subscription already active.',
                'expiry_date' => $existing->end_date
            ]);
        }

        try {
            // 1. Initialize Google Client
            $client = new Client();
            $client->setAuthConfig(storage_path('app/google-service-account.json'));
            $client->addScope(AndroidPublisher::ANDROIDPUBLISHER);

            $service = new AndroidPublisher($client);
            $packageName = config('app.android_package_name', 'com.cribsarena.cribsagent');

            // 2. Fetch Subscription State from Google
            // Note: Use subscriptions_v2 for newer integrations if needed, but subscriptions is standard
            $subscription = $service->purchases_subscriptions->get($packageName, $productId, $purchaseToken);

            // 3. Validate Status (0 = Subscription purchased, 1 = Canceled, etc.)
            // For v1 get(), we check expiryTimeMillis or paymentState
            if (!$subscription->getExpiryTimeMillis() || $subscription->getExpiryTimeMillis() < (time() * 1000)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Subscription has expired or is invalid.'
                ], 400);
            }

            // 4. Update Database
            DB::beginTransaction();

            // Mark previous as Expired
            DB::table('paid_subscribers')
                ->where('agent_id', $agent->agent_id)
                ->where('status', 'Active')
                ->update(['status' => 'Expired']);

            // Insert new subscription
            $endDate = date('Y-m-d H:i:s', $subscription->getExpiryTimeMillis() / 1000);

            DB::table('paid_subscribers')->insert([
                'agent_id' => $agent->agent_id,
                'plan_id' => $planId,
                'start_date' => now(),
                'end_date' => $endDate,
                'upload_count' => 0,
                'amount_paid' => $plan->price,
                'payment_method' => 'Google Play',
                'paystack_reference' => $purchaseToken, // Using purchaseToken as reference
                'status' => 'Active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Create notification
            DB::table('notifications')->insert([
                'receiver_id' => $agent->agent_id,
                'receiver_type' => 'agent',
                'type' => 'subscription',
                'title' => 'Subscription Activated',
                'body' => "Your {$plan->name} plan is now active via Google Play Billing.",
                'is_read' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Subscription verified and activated successfully.',
                'expiry_date' => $endDate
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('GoogleBilling Verification Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to verify subscription with Google. Please try again later.'
            ], 500);
        }
    }
}
