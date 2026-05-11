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
use Illuminate\Support\Facades\Mail;
use App\Mail\SubscriptionActivatedMail;
use App\Services\FCMService;

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

        Log::info("GoogleBilling: Starting verification", [
            'productId' => $productId,
            'purchaseToken' => substr($purchaseToken, 0, 20) . '...',
            'agent_id' => $agent->agent_id ?? 'unknown'
        ]);

        // 1. Mapping Check
        if (!isset($this->productMapping[$productId])) {
            Log::error("GoogleBilling: Unmapped productId: $productId");
            return response()->json(['success' => false, 'message' => 'Invalid product identifier.'], 422);
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
                Log::error("GoogleBilling: Service account file missing at: $serviceAccountPath");
                return response()->json(['success' => false, 'message' => 'Server configuration error.'], 500);
            }
            
            $client->setAuthConfig($serviceAccountPath);
            $client->addScope(AndroidPublisher::ANDROIDPUBLISHER);
            $service = new AndroidPublisher($client);
            $primaryPackageName = 'com.cribsarena.cribsagent';
            $fallbackPackageName = 'com.cribsarena.agents';
            
            $subscription = null;
            $isSubscription = true;
            $usedPackageName = $primaryPackageName;

            // 3. Attempt Verification Logic with Modern v2 + Legacy Fallbacks
            $verifyWithPackage = function($pName) use ($service, $productId, $purchaseToken, &$isSubscription) {
                // Path A: Modern Subscriptions v2 (Recommended for Billing Library 5+)
                try {
                    Log::info("GoogleBilling: [Path A - Modern v2] Verifying: $pName");
                    // Note: v2.get only needs pName and token
                    $subV2 = $service->purchases_subscriptionsv2->get($pName, $purchaseToken);
                    
                    Log::info("GoogleBilling: [Path A - Modern v2] SUCCESS. State: " . $subV2->getSubscriptionState());
                    
                    // Convert v2 structure to our local format
                    $compat = new \stdClass();
                    $lineItems = $subV2->getLineItems();
                    $item = !empty($lineItems) ? $lineItems[0] : null;
                    
                    if (!$item) {
                        throw new \Exception("No line items found in v2 purchase.");
                    }

                    // Map v2 fields to our internal logic (v2 returns ISO 8601 strings)
                    $expiryStr = $item->getExpiryTime();
                    $compat->expiryTimeMillis = strtotime($expiryStr) * 1000;
                    
                    $compat->acknowledgementState = $subV2->getAcknowledgementState() === 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED' ? 1 : 0;
                    $compat->purchaseState = $subV2->getSubscriptionState() === 'SUBSCRIPTION_STATE_ACTIVE' ? 0 : 1;
                    $compat->productId = $item->getProductId();
                    
                    return [$compat, true];
                } catch (\Exception $e) {
                    Log::warning("GoogleBilling: [Path A - Modern v2] FAILED: " . $e->getMessage());
                    
                    // Path B: Legacy Subscription v1
                    try {
                        Log::info("GoogleBilling: [Path B - Legacy v1] Verifying: $pName | $productId");
                        $subV1 = $service->purchases_subscriptions->get($pName, $productId, $purchaseToken);
                        Log::info("GoogleBilling: [Path B - Legacy v1] SUCCESS");
                        return [$subV1, true];
                    } catch (\Exception $e2) {
                        Log::warning("GoogleBilling: [Path B - Legacy v1] FAILED: " . $e2->getMessage());
                        
                        // Path C: One-time Product / Prepaid
                        try {
                            Log::info("GoogleBilling: [Path C - Product] Verifying: $pName | $productId");
                            $prod = $service->purchases_products->get($pName, $productId, $purchaseToken);
                            Log::info("GoogleBilling: [Path C - Product] SUCCESS");
                            
                            $compat = new \stdClass();
                            $compat->acknowledgementState = $prod->getAcknowledgementState();
                            $compat->expiryTimeMillis = time() * 1000 + (30 * 24 * 60 * 60 * 1000); 
                            $compat->purchaseState = $prod->getPurchaseState();
                            return [$compat, false];
                        } catch (\Exception $e3) {
                            Log::error("GoogleBilling: [Path C - Product] FAILED: " . $e3->getMessage());
                            return [null, false];
                        }
                    }
                }
            };

            // Try Primary Package
            [$subscription, $isSubscription] = $verifyWithPackage($primaryPackageName);
            
            // If failed, try Fallback Package
            if (!$subscription) {
                Log::info("GoogleBilling: Retrying with fallback package name: $fallbackPackageName");
                $usedPackageName = $fallbackPackageName;
                [$subscription, $isSubscription] = $verifyWithPackage($fallbackPackageName);
            }

            if (!$subscription) {
                Log::error("GoogleBilling: Final verification failure. All paths exhausted.");
                return response()->json([
                    'success' => false, 
                    'message' => 'Google Play could not find this purchase. Ensure you are using the same Google Account that made the purchase.',
                    'debug_productId' => $productId,
                    'debug_package' => $primaryPackageName
                ], 404);
            }

            $packageName = $usedPackageName;

            // 4. Validate Expiry / Purchase State
            $expiryMillis = (int) $subscription->expiryTimeMillis; 
            if (isset($subscription->getExpiryTimeMillis)) {
                $expiryMillis = (int) $subscription->getExpiryTimeMillis();
            }

            $ackState = $subscription->acknowledgementState;
            if (isset($subscription->getAcknowledgementState)) {
                $ackState = $subscription->getAcknowledgementState();
            }

            Log::info("GoogleBilling: Verification Success. Package: $packageName, Type: " . ($isSubscription ? 'Subscription' : 'Product'));

            if ($expiryMillis < (time() * 1000)) {
                Log::warning("GoogleBilling: Purchase expired at: " . date('Y-m-d H:i:s', $expiryMillis / 1000));
                return response()->json(['success' => false, 'message' => 'Purchase has expired.'], 400);
            }

            $endDate = date('Y-m-d H:i:s', $expiryMillis / 1000);

            // 5. Database Transaction
            DB::beginTransaction();
            try {
                $existingRecord = DB::table('paid_subscribers')
                    ->where('paystack_reference', $purchaseToken)
                    ->first();

                if (!$existingRecord) {
                    Log::info("GoogleBilling: NEW purchase - Recording in database");

                    DB::table('paid_subscribers')
                        ->where('agent_id', $agent->agent_id)
                        ->where('status', 'Active')
                        ->update(['status' => 'Expired', 'updated_at' => now()]);

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
                    $platformFee = DB::table('platform_settings')->where('key_name', 'platform_fee')->value('value') ?? 300.00;
                    DB::table('platform_fee_logs')->insert([
                        'transaction_reference' => $purchaseToken . '_' . time(),
                        'source_app' => 'agent_app',
                        'user_id' => $agent->agent_id,
                        'amount' => $platformFee,
                        'description' => "Platform fee for {$plan->name} (Google Play)",
                        'created_at' => now(),
                    ]);

                    // Notifications
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

                    try {
                        $fcmService = new FCMService();
                        $fcmService->sendToUserOrAgent($agent->agent_id, 'agent', 'Plan Activated', "Your {$plan->name} plan is now active.", ['type' => 'subscription']);
                    } catch (\Exception $e) {}

                } else {
                    Log::info("GoogleBilling: Already processed (idempotent)");
                }

                // 6. Acknowledge with Google
                if ($ackState == 0) {
                    try {
                        if ($isSubscription) {
                            $ackReq = new \Google\Service\AndroidPublisher\SubscriptionPurchasesAcknowledgeRequest();
                            $service->purchases_subscriptions->acknowledge($packageName, $productId, $purchaseToken, $ackReq);
                        } else {
                            $ackReq = new \Google\Service\AndroidPublisher\ProductPurchasesAcknowledgeRequest();
                            $service->purchases_products->acknowledge($packageName, $productId, $purchaseToken, $ackReq);
                        }
                        Log::info("GoogleBilling: ✅ Acknowledged successfully");
                    } catch (\Exception $ackError) {
                        Log::error("GoogleBilling: Acknowledgment failed: " . $ackError->getMessage());
                        // We don't rollback here as the database is consistent with the purchase
                    }
                }

                DB::commit();
                return response()->json([
                    'success' => true, 
                    'message' => 'Subscription verified and activated.',
                    'expiry_date' => $endDate
                ]);

            } catch (\Exception $dbError) {
                DB::rollBack();
                Log::error("GoogleBilling: DB Error: " . $dbError->getMessage());
                return response()->json(['success' => false, 'message' => 'Database sync failed.'], 500);
            }

        } catch (\Exception $e) {
            Log::error("GoogleBilling: Critical error: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Unexpected error: ' . $e->getMessage()], 500);
        }

    }
}
