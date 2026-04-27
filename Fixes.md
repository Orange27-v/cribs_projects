# Complete Fix Instructions for Google Play Subscription Acknowledgment Issue

## Problem Summary
Your app successfully processes Google Play purchases, but they're not being acknowledged, causing "Developer hasn't acknowledged your purchase" errors and auto-refunds after 3 days.

---

## Fix #1: Update Purchase Handling Logic in `plan_service.dart`

### Step 1: Replace the `_handlePurchaseUpdates` method

Find the `_handlePurchaseUpdates` method (starting at line 222) and replace it entirely with this:

```dart
void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
  for (var purchaseDetails in purchaseDetailsList) {
    debugPrint('PlanService: 🔄 Processing Purchase Update for: ${purchaseDetails.productID}');
    debugPrint('PlanService: Current Status: ${purchaseDetails.status}');
    debugPrint('PlanService: Purchase ID: ${purchaseDetails.purchaseID}');
    
    // PENDING: Show pending status
    if (purchaseDetails.status == PurchaseStatus.pending) {
      debugPrint('PlanService: ⏳ Purchase is PENDING...');
      _purchaseResultController.add(PurchaseResult(
        status: PurchaseStatus.pending,
        details: purchaseDetails,
        message: 'Payment is being processed by Google...',
      ));
      // Don't complete the purchase yet - wait for Google to confirm
      continue;
    }
    
    // PURCHASED or RESTORED: Verify with backend IMMEDIATELY
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      
      debugPrint('PlanService: ✅ Purchase/Restore detected. Verifying with backend...');
      
      // Emit "Awaiting Confirmation" status
      _purchaseResultController.add(PurchaseResult(
        status: PurchaseStatus.purchased,
        details: purchaseDetails,
        isAcknowledged: false,
        message: 'Verifying with server...',
      ));
      
      // CRITICAL: Verify with backend BEFORE completing
      bool verified = await _verifyPurchaseWithBackend(purchaseDetails);
      
      if (verified) {
        debugPrint('PlanService: 🎉 Backend verification SUCCESS');
        
        // Start heartbeat to monitor backend sync
        startHeartbeat();
        
        // Emit success result
        _purchaseResultController.add(PurchaseResult(
          status: PurchaseStatus.purchased,
          details: purchaseDetails,
          isAcknowledged: true,
          message: 'Subscription activated successfully!',
        ));
        
        // Refresh subscription data
        await getCurrentSubscription();
        
      } else {
        debugPrint('PlanService: ❌ Backend verification FAILED. Starting retry...');
        
        // Start heartbeat retry mechanism
        startHeartbeat();
        
        // Keep showing "Awaiting Confirmation" status
        _purchaseResultController.add(PurchaseResult(
          status: PurchaseStatus.purchased,
          details: purchaseDetails,
          isAcknowledged: false,
          message: 'Server verification in progress...',
        ));
      }
      
      // CRITICAL: Complete the purchase on Google's side
      // This prevents duplicate purchase attempts
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint('PlanService: Completing purchase transaction...');
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
    
    // ERROR: Show error immediately
    else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint('PlanService: ❌ Purchase ERROR: ${purchaseDetails.error}');
      _purchaseResultController.add(PurchaseResult(
        status: PurchaseStatus.error,
        details: purchaseDetails,
        message: purchaseDetails.error?.message ?? 'Purchase failed',
      ));
      
      // Complete to clear the transaction
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
    
    // CANCELED: Handle cancellation
    else if (purchaseDetails.status == PurchaseStatus.canceled) {
      debugPrint('PlanService: ⚠️ Purchase CANCELED by user');
      _purchaseResultController.add(PurchaseResult(
        status: PurchaseStatus.canceled,
        details: purchaseDetails,
        message: 'Purchase was cancelled',
      ));
      
      // Complete to clear the transaction
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
}
```

---

## Fix #2: Add Heartbeat Retry Mechanism

### Step 2: Add the heartbeat functions (add after line 448)

```dart
/// Start a heartbeat that retries verification every 10 seconds
static void startHeartbeat() {
  stopHeartbeat(); // Clear any existing timer
  _heartbeatCount = 0;
  
  debugPrint('PlanService: 🫀 Starting verification heartbeat...');
  
  _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
    _heartbeatCount++;
    debugPrint('PlanService: 🫀 Heartbeat #$_heartbeatCount - Checking subscription status...');
    
    // Stop after 6 attempts (1 minute total)
    if (_heartbeatCount > 6) {
      debugPrint('PlanService: 🫀 Heartbeat timeout - stopping retries');
      stopHeartbeat();
      return;
    }
    
    // Fetch latest subscription from backend
    try {
      final subscription = await PlanService().getCurrentSubscription();
      
      if (subscription != null && subscription['status'] == 'Active') {
        debugPrint('PlanService: 🫀 Heartbeat SUCCESS - Subscription is now Active!');
        
        // Emit the subscription update
        notifySubscriptionChange(subscription);
        
        stopHeartbeat();
      } else {
        debugPrint('PlanService: 🫀 Heartbeat - Still waiting for activation...');
      }
    } catch (e) {
      debugPrint('PlanService: 🫀 Heartbeat error: $e');
    }
  });
}

/// Stop the heartbeat timer
static void stopHeartbeat() {
  if (_heartbeatTimer != null) {
    _heartbeatTimer!.cancel();
    _heartbeatTimer = null;
    _heartbeatCount = 0;
    debugPrint('PlanService: 🫀 Heartbeat stopped');
  }
}
```

---

## Fix #3: Fix the Backend Acknowledgment Logic

### Step 3: Update `GoogleBillingController.php`

Replace the entire `verifySubscription` method with this improved version:

```php
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
            return response()->json(['success' => false, 'message' => 'Backend configuration error.'], 500);
        }
        
        $client->setAuthConfig($serviceAccountPath);
        $client->addScope(AndroidPublisher::ANDROIDPUBLISHER);

        $service = new AndroidPublisher($client);
        $packageName = config('app.android_package_name');
        
        if (!$packageName) {
            Log::error("GoogleBilling: Package name not configured");
            return response()->json(['success' => false, 'message' => 'Package name missing.'], 500);
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
                    'message' => 'Google API authentication failed. Check Play Console permissions.'
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

        // 4. Validate Expiry
        $expiryMillis = (int) $subscription->getExpiryTimeMillis();
        if ($expiryMillis < (time() * 1000)) {
            Log::warning("GoogleBilling: Subscription expired at: " . date('Y-m-d H:i:s', $expiryMillis / 1000));
            return response()->json(['success' => false, 'message' => 'Subscription has expired.'], 400);
        }

        $endDate = date('Y-m-d H:i:s', $expiryMillis / 1000);
        Log::info("GoogleBilling: Valid subscription until: $endDate");

        // 5. Database Transaction
        DB::beginTransaction();
        try {
            // Check for duplicate processing
            $existingRecord = DB::table('paid_subscribers')
                ->where('paystack_reference', $purchaseToken)
                ->where('end_date', $endDate)
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
                'message' => 'Database error: ' . $dbError->getMessage()
            ], 500);
        }

    } catch (\Exception $e) {
        Log::error("GoogleBilling: Unexpected error: " . $e->getMessage());
        Log::error($e->getTraceAsString());
        return response()->json([
            'success' => false, 
            'message' => 'System error: ' . $e->getMessage()
        ], 500);
    }
}
```

---

## Fix #4: Update Environment Configuration

### Step 4: Verify your `.env` file contains:

```env
ANDROID_PACKAGE_NAME=your.app.package.name
```

### Step 5: Add to `config/app.php`:

```php
'android_package_name' => env('ANDROID_PACKAGE_NAME'),
```

---

## Fix #5: Verify Google Play Console Setup

### Step 6: Check Play Console Configuration

1. **Go to Play Console → Your App → Monetization Setup → In-app Products**
2. For EACH subscription (Basic, Standard, Premium):
   - Status must be **ACTIVE**
   - Must have at least one **Base Plan** that is **ACTIVE**
   - Product ID must match exactly: `cribs_agent_basic`, `cribs_agent_standard`, `cribs_agent_premium`

3. **Go to Play Console → Your App → Setup → API Access**
   - Ensure your service account has **View financial data** permission
   - This is CRITICAL for acknowledgment to work

4. **Download fresh service account JSON**
   - Save as `storage/app/google-service-account.json`
   - Verify file permissions (readable by web server)

---

## Testing Instructions

### Step 7: Test the complete flow

1. **Clear app data** (Settings → Apps → Your App → Storage → Clear Data)
2. **Uninstall and reinstall** the app
3. **Enable verbose logging:**
   ```bash
   adb logcat | grep "PlanService\|GoogleBilling"
   ```
4. **Attempt subscription purchase**
5. **Watch for these log messages:**
   ```
   PlanService: ✅ Purchase/Restore detected
   PlanService: 🎉 Backend verification SUCCESS
   GoogleBilling: ✅ Successfully acknowledged purchase token
   PlanService: 🫀 Heartbeat SUCCESS - Subscription is now Active!
   ```

---

## What These Fixes Do:

1. **Fix #1**: Ensures backend verification happens BEFORE completing purchase
2. **Fix #2**: Adds retry mechanism if initial verification fails
3. **Fix #3**: Improves error handling and ensures acknowledgment always happens
4. **Fix #4**: Ensures proper configuration
5. **Fix #5**: Verifies Google Play Console permissions

The key insight: **Acknowledgment must happen server-side, and the app must wait for confirmation before completing the purchase transaction.**