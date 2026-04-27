<?php

namespace App\Http\Controllers\General;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use App\Models\AgentPlan;
use Google\Client;
use Google\Service\AndroidPublisher;

class GoogleWebhookController extends Controller
{
    /**
     * Map Google Product IDs to Database Plan IDs
     */
    protected $productMapping = [
        'cribs_agent_basic' => 1,
        'cribs_agent_standard' => 2,
        'cribs_agent_premium' => 3,
    ];

    /**
     * Handle RTDN Webhook from Google Cloud Pub/Sub
     */
    public function handleRTDN(Request $request)
    {
        Log::info('Google Webhook RTDN: Request received.');

        try {
            // Extract the base64 encoded data from the Pub/Sub message
            $messageData = $request->input('message.data');
            
            if (!$messageData) {
                Log::warning('Google Webhook RTDN: Missing message.data in payload.');
                // Always return 200 to Pub/Sub to prevent infinite retries
                return response()->json(['status' => 'ignored'], 200);
            }

            // Decode base64
            $decodedJson = base64_decode($messageData);
            $notification = json_decode($decodedJson, true);

            if (!$notification) {
                Log::error('Google Webhook RTDN: Failed to decode JSON payload.');
                return response()->json(['status' => 'error'], 200);
            }

            Log::info('Google Webhook RTDN Payload:', $notification);

            // Check if it's a subscription notification
            if (!isset($notification['subscriptionNotification'])) {
                Log::info('Google Webhook RTDN: Not a subscription notification (might be a test ping). Ignoring.');
                return response()->json(['status' => 'ok'], 200);
            }

            $subNotif = $notification['subscriptionNotification'];
            $notificationType = $subNotif['notificationType'] ?? null;
            $purchaseToken = $subNotif['purchaseToken'] ?? null;
            $productId = $subNotif['subscriptionId'] ?? null;

            if (!$purchaseToken || !$productId) {
                Log::error('Google Webhook RTDN: Missing purchaseToken or subscriptionId.');
                return response()->json(['status' => 'error'], 200);
            }

            // notificationType 2 = SUBSCRIPTION_RENEWED
            // notificationType 4 = SUBSCRIPTION_PURCHASED
            if (in_array($notificationType, [2, 4])) {
                Log::info("Google Webhook RTDN: Processing notificationType $notificationType for productId $productId");
                $this->processSubscription($productId, $purchaseToken);
            } else {
                Log::info("Google Webhook RTDN: Ignoring notificationType $notificationType");
            }

            return response()->json(['status' => 'success'], 200);

        } catch (\Exception $e) {
            Log::error('Google Webhook RTDN Exception: ' . $e->getMessage());
            Log::error($e->getTraceAsString());
            return response()->json(['status' => 'error_handled'], 200);
        }
    }

    private function processSubscription($productId, $purchaseToken)
    {
        if (!isset($this->productMapping[$productId])) {
            Log::error("Google Webhook RTDN: Unmapped productId: $productId");
            return;
        }

        $planId = $this->productMapping[$productId];
        $plan = AgentPlan::find($planId);
        if (!$plan) {
            Log::error("Google Webhook RTDN: Plan ID $planId not found.");
            return;
        }

        // Initialize Google Client
        $client = new Client();
        $serviceAccountPath = storage_path('app/google-service-account.json');
        
        if (!file_exists($serviceAccountPath)) {
            Log::error("Google Webhook RTDN: Service account file not found.");
            return;
        }
        
        $client->setAuthConfig($serviceAccountPath);
        $client->addScope(AndroidPublisher::ANDROIDPUBLISHER);

        $service = new AndroidPublisher($client);
        $packageName = config('app.android_package_name');
        
        if (!$packageName) {
            Log::error("Google Webhook RTDN: Package name not configured.");
            return;
        }

        try {
            // Fetch latest subscription from Google Play API
            $subscription = $service->purchases_subscriptions->get($packageName, $productId, $purchaseToken);
            
            $expiryMillis = (int) $subscription->getExpiryTimeMillis();
            if ($expiryMillis < (time() * 1000)) {
                Log::warning("Google Webhook RTDN: Subscription expired at: " . date('Y-m-d H:i:s', $expiryMillis / 1000));
                return;
            }

            $endDate = date('Y-m-d H:i:s', $expiryMillis / 1000);

            // Find the agent who owns this subscription by looking up previous payments
            // The purchaseToken never changes for renewals.
            $existingSub = DB::table('paid_subscribers')
                ->where('paystack_reference', $purchaseToken)
                ->orderBy('id', 'asc')
                ->first();

            if (!$existingSub) {
                Log::warning("Google Webhook RTDN: Could not find any existing subscription for token: " . substr($purchaseToken, 0, 20) . "...");
                // If it's the very first purchase (type 4) and the webhook arrived before the app request, 
                // we won't know which agent it belongs to because Google doesn't send the agent_id!
                // We rely on the app to send the first POST request to bind the token to the agent_id.
                return;
            }

            $agentId = $existingSub->agent_id;

            DB::beginTransaction();
            try {
                // Idempotency check: Have we processed this exact end_date already?
                $processedRecord = DB::table('paid_subscribers')
                    ->where('paystack_reference', $purchaseToken)
                    ->where('end_date', $endDate)
                    ->first();

                if (!$processedRecord) {
                    Log::info("Google Webhook RTDN: NEW subscription cycle - Recording in database for Agent $agentId");

                    // Expire old active plans
                    DB::table('paid_subscribers')
                        ->where('agent_id', $agentId)
                        ->where('status', 'Active')
                        ->update([
                            'status' => 'Expired',
                            'updated_at' => now()
                        ]);

                    // Insert new cycle
                    DB::table('paid_subscribers')->insert([
                        'agent_id' => $agentId,
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
                        'transaction_reference' => $purchaseToken . '_rtdn_' . $expiryMillis,
                        'source_app' => 'agent_app',
                        'user_id' => $agentId,
                        'amount' => $platformFee,
                        'description' => "Platform fee for {$plan->name} (Google Play Auto-Renewal)",
                        'created_at' => now(),
                    ]);

                    // Send notification
                    DB::table('notifications')->insert([
                        'receiver_id' => $agentId,
                        'receiver_type' => 'agent',
                        'type' => 'subscription',
                        'title' => 'Plan Renewed',
                        'body' => "Your {$plan->name} plan has automatically renewed until " . date('M d, Y', $expiryMillis/1000),
                        'is_read' => 0,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                    
                    Log::info("Google Webhook RTDN: Cycle recorded successfully for Agent $agentId");
                } else {
                    Log::info("Google Webhook RTDN: Subscription cycle already processed (idempotent).");
                }

                // Check acknowledgement
                if ($subscription->getAcknowledgementState() == 0) {
                    Log::info("Google Webhook RTDN: Acknowledging purchase...");
                    $acknowledgeRequest = new \Google\Service\AndroidPublisher\SubscriptionPurchasesAcknowledgeRequest();
                    $service->purchases_subscriptions->acknowledge(
                        $packageName, 
                        $productId, 
                        $purchaseToken, 
                        $acknowledgeRequest
                    );
                    Log::info("Google Webhook RTDN: Acknowledged successfully.");
                }

                DB::commit();

            } catch (\Exception $dbError) {
                DB::rollBack();
                Log::error("Google Webhook RTDN Database Error: " . $dbError->getMessage());
            }

        } catch (\Google\Service\Exception $ge) {
            Log::error("Google Webhook RTDN API Error: " . $ge->getMessage());
        }
    }
}
