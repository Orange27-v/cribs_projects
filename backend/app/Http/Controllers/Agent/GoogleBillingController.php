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

        Log::info("GoogleBilling: Verification request for productId: $productId, agent: {$agent->agent_id}");

        // 1. Mapping Check
        if (!isset($this->productMapping[$productId])) {
            Log::error("GoogleBilling: Unmapped productId: $productId");
            return response()->json(['success' => false, 'message' => 'Invalid product identifier.'], 400);
        }

        $planId = $this->productMapping[$productId];
        $plan = AgentPlan::find($planId);
        if (!$plan) {
            return response()->json(['success' => false, 'message' => 'Plan not found.'], 404);
        }

        try {
            // 2. Initialize Google Client
            $client = new Client();
            $serviceAccountPath = storage_path('app/google-service-account.json');
            
            if (!file_exists($serviceAccountPath)) {
                Log::error("GoogleBilling: Service account file not found at: $serviceAccountPath");
                return response()->json(['success' => false, 'message' => 'System configuration error. Please contact support.'], 500);
            }
            
            $client->setAuthConfig($serviceAccountPath);
            $client->addScope(AndroidPublisher::ANDROIDPUBLISHER);

            $service = new AndroidPublisher($client);
            // HARDCODED for maximum resilience against config/env issues during testing
            $packageName = 'com.cribsarena.cribsagent';
            
            if (!$packageName) {
                Log::error("GoogleBilling: Package name not configured in .env or config");
                return response()->json(['success' => false, 'message' => 'App verification failed. Please try again later.'], 500);
            }

            Log::info("GoogleBilling: Fetching subscription from Google Play API...");

            // 3. Fetch from Google (Source of Truth)
            try {
                $subscription = $service->purchases_subscriptions->get($packageName, $productId, $purchaseToken);
            } catch (\Google\Service\Exception $ge) {
                $errorMsg = $ge->getMessage();
                $statusCode = $ge->getCode();
                
                Log::error("GoogleBilling: Google API Error [$statusCode]: $errorMsg");
                
                if ($statusCode == 401 || $statusCode == 403) {
                    return response()->json([
                        'success' => false, 
                        'message' => 'Server authentication failed. We are looking into this.'
                    ], 403);
                }
                
                if ($statusCode == 404) {
                    return response()->json([
                        'success' => false, 
                        'message' => 'Purchase not found. The token may be invalid or expired.'
                    ], 404);
                }
                
                return response()->json(['success' => false, 'message' => "Google API error: $errorMsg"], 500);
            }

            Log::info("GoogleBilling: Google API response received. Acknowledgment state: " . $subscription->getAcknowledgementState());

            // 4. Validate Expiry (with 5-minute grace period for sandbox/drift)
            $expiryMillis = (int) $subscription->getExpiryTimeMillis();
            $gracePeriodMillis = 5 * 60 * 1000;
            
            if (($expiryMillis + $gracePeriodMillis) < (time() * 1000)) {
                Log::warning("GoogleBilling: Subscription truly expired at: " . date('Y-m-d H:i:s', $expiryMillis / 1000));
                return response()->json(['success' => false, 'message' => 'Subscription has expired.'], 400);
            }

            $endDate = date('Y-m-d H:i:s', $expiryMillis / 1000);
            Log::info("GoogleBilling: Valid subscription until: $endDate");

            // 5. Database Transaction
            DB::beginTransaction();
            try {
                // Check for duplicate processing (Token-only check for robustness)
                $existingRecord = DB::table('paid_subscribers')
                    ->where('paystack_reference', $purchaseToken)
                    ->first();

                if (!$existingRecord) {
                    Log::info("GoogleBilling: NEW subscription cycle - Recording in database");

                    // Expire all existing active plans
                    DB::table('paid_subscribers')
                        ->where('agent_id', $agent->agent_id)
                        ->where('status', 'Active')
                        ->update([
                            'status' => 'Expired',
                            'updated_at' => now()
                        ]);

                    // Insert new subscription record
                    DB::table('paid_subscribers')->insert([
                        'agent_id' => $agent->agent_id,
                        'plan_id' => $planId,
                        'start_date' => now(),
                        'end_date' => $endDate,
                        'amount_paid' => $plan->price,
                        'payment_method' => 'Google Play',
                        'paystack_reference' => $purchaseToken,
                        'status' => 'Active',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    // Log platform fee
                    $platformFee = DB::table('platform_settings')
                        ->where('key_name', 'platform_fee')
                        ->value('value') ?? 300.00;
                        
                    DB::table('platform_fee_logs')->insert([
                        'transaction_reference' => $purchaseToken . '_' . $expiryMillis,
                        'source_app' => 'agent_app',
                        'user_id' => $agent->agent_id,
                        'amount' => $platformFee,
                        'description' => "Platform fee for {$plan->name} (Google Play)",
                        'created_at' => now(),
                    ]);

                    // Send notification
                    DB::table('notifications')->insert([
                        'receiver_id' => $agent->agent_id,
                        'receiver_type' => 'agent',
                        'type' => 'subscription',
                        'title' => 'Plan Activated',
                        'body' => "Your {$plan->name} plan is now active until " . date('M d, Y', $expiryMillis/1000),
                        'is_read' => 0,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    Log::info("GoogleBilling: Database records created successfully");
                } else {
                    Log::info("GoogleBilling: Subscription cycle already processed (idempotent)");
                }

                // 6. CRITICAL: Acknowledge with Google (ALWAYS attempt, even if already acknowledged)
                $ackState = $subscription->getAcknowledgementState();
                Log::info("GoogleBilling: Acknowledgment state before: $ackState (0=unacknowledged, 1=acknowledged)");
                
                if ($ackState == 0) {
                    Log::info("GoogleBilling: Sending acknowledgment to Google...");
                    
                    try {
                        $acknowledgeRequest = new \Google\Service\AndroidPublisher\SubscriptionPurchasesAcknowledgeRequest();
                        $service->purchases_subscriptions->acknowledge(
                            $packageName, 
                            $productId, 
                            $purchaseToken, 
                            $acknowledgeRequest
                        );
                        
                        Log::info("GoogleBilling: ✅ Successfully acknowledged purchase token: " . substr($purchaseToken, 0, 15) . "...");
                        
                    } catch (\Exception $ackError) {
                        // Log but don't fail - acknowledgment might have succeeded on Google's side
                        Log::error("GoogleBilling: Acknowledgment call failed: " . $ackError->getMessage());
                        
                        // Rollback database changes if acknowledgment fails
                        DB::rollBack();
                        return response()->json([
                            'success' => false, 
                            'message' => 'Failed to acknowledge with Google: ' . $ackError->getMessage()
                        ], 500);
                    }
                } else {
                    Log::info("GoogleBilling: Purchase already acknowledged (state: $ackState)");
                }

                DB::commit();
                
                Log::info("GoogleBilling: ✅ Complete verification success for agent {$agent->agent_id}");
                
                return response()->json([
                    'success' => true, 
                    'message' => 'Subscription verified and activated.',
                    'expiry_date' => $endDate,
                    'plan_name' => $plan->name
                ]);

            } catch (\Exception $dbError) {
                DB::rollBack();
                Log::error("GoogleBilling: Database error: " . $dbError->getMessage());
                return response()->json([
                    'success' => false, 
                    'message' => 'Failed to activate your plan. Please contact support.'
                ], 500);
            }

        } catch (\Exception $e) {
            Log::error("GoogleBilling: Unexpected error: " . $e->getMessage());
            Log::error($e->getTraceAsString());
            return response()->json([
                'success' => false, 
                'message' => 'An unexpected system error occurred. Please try again later.'
            ], 500);
        }
    }
}
