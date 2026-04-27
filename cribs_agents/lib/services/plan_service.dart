import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/agent_plan.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PlanService {
  // Static stream controller for subscription updates across the app
  static final StreamController<Map<String, dynamic>?> _subscriptionController =
      StreamController<Map<String, dynamic>?>.broadcast();

  static Timer? _monitorTimer;
  static Map<String, dynamic>? _cachedSubscription;
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static List<ProductDetails> _products = [];
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Static stream controller for specific purchase results (navigation triggers)
  static final StreamController<PurchaseResult> _purchaseResultController =
      StreamController<PurchaseResult>.broadcast();

  static bool verboseLogging = true;

  static Timer? _heartbeatTimer;
  static int _heartbeatCount = 0;

  // New: Synchronization for IAP initialization
  static final Completer<void> _initCompleter = Completer<void>();
  static bool _initializationCalled = false;
  static bool _isStoreAvailable = false;

  /// Map Google Product IDs to internal Plan Names
  static const Map<String, String> productMappings = {
    'cribs_agent_basic': 'Starter',
    'cribs_agent_standard': 'Standard',
    'cribs_agent_premium': 'Premium',
  };

  /// Internal logging helper for PlanService
  static void _log(String message, {bool isVerbose = false, Object? error}) {
    if (isVerbose && !verboseLogging) return;
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 12);
    debugPrint('[$timestamp] PlanService: $message');
    if (error != null) {
      debugPrint('[$timestamp] PlanService: 🚩 ERROR DETAILS: $error');
    }
  }

  /// Stream of subscription updates for real-time UI updates
  static Stream<Map<String, dynamic>?> get subscriptionStream =>
      _subscriptionController.stream;

  /// Stream of specific purchase results for UI feedback
  static Stream<PurchaseResult> get purchaseResultStream =>
      _purchaseResultController.stream;

  /// Notify all listeners of subscription change and update cache
  static void notifySubscriptionChange(Map<String, dynamic>? subscription) {
    _cachedSubscription = subscription;
    _subscriptionController.add(subscription);
    _checkAndStartMonitoring();
  }

  /// Start monitoring if we have an active subscription
  static void _checkAndStartMonitoring() {
    _monitorTimer?.cancel();

    if (_cachedSubscription != null &&
        _cachedSubscription!['status'] == 'Active') {
      debugPrint('PlanService: Starting subscription monitor');
      _monitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _validateSubscription();
      });
    } else {
      debugPrint('PlanService: Stopping subscription monitor (No active sub)');
    }
  }

  static void _validateSubscription() {
    if (_cachedSubscription == null) {
      _monitorTimer?.cancel();
      return;
    }

    final endDateStr = _cachedSubscription!['end_date'];
    if (endDateStr != null) {
      try {
        final endDate = DateTime.parse(endDateStr);
        if (DateTime.now().isAfter(endDate)) {
          debugPrint('PlanService: Subscription expired during monitoring');
          // Update local status
          final updatedSub = Map<String, dynamic>.from(_cachedSubscription!);
          updatedSub['status'] = 'Expired'; 

          notifySubscriptionChange(null); 
          _subscriptionController.add(_cachedSubscription); 
        }
      } catch (e) {
        debugPrint('PlanService: Error parsing date in monitor: $e');
      }
    }
  }

  /// Dispose timer when app functionality might not need it
  static void dispose() {
    _monitorTimer?.cancel();
    _purchaseSubscription?.cancel();
    _subscriptionController.close();
  }

  /// Initialize In-App Purchases and load products
  Future<void> initializeInAppPurchase() async {
    if (_initializationCalled) return _initCompleter.future;
    _initializationCalled = true;

    debugPrint('PlanService: Initializing In-App Purchase...');

    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('PlanService: Google Play Store NOT available on this device');
        _isStoreAvailable = false;
        if (!_initCompleter.isCompleted) _initCompleter.complete();
        return;
      }

      _isStoreAvailable = true;
      debugPrint('PlanService: Google Play Store is available');

      // Listen to purchase updates
      await _purchaseSubscription?.cancel();
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchaseDetailsList) {
          _log('Received purchase updates: ${purchaseDetailsList.length} items', isVerbose: true);
          _handlePurchaseUpdates(purchaseDetailsList);
        },
        onDone: () => _log('Purchase stream closed'),
        onError: (error) => _log('Purchase stream error', error: error),
      );

      // Load products
      const Set<String> _kIds = {
        'cribs_agent_basic',
        'cribs_agent_standard',
        'cribs_agent_premium'
      };

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_kIds);

      _products = response.productDetails;
      debugPrint('PlanService: Successfully loaded ${_products.length} products');
    } catch (e) {
      debugPrint('PlanService: Critical error during IAP initialization: $e');
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  /// Initiate a Google Play purchase
  Future<void> buySubscription(AgentPlan plan) async {
    if (!_initializationCalled) {
      initializeInAppPurchase();
    }
    await _initCompleter.future;

    if (!_isStoreAvailable) {
      throw Exception('Google Play Store is not available on this device.');
    }

    final productId = productMappings.entries
        .firstWhere((entry) => entry.value == plan.name,
            orElse: () => const MapEntry('', ''))
        .key;

    if (productId.isEmpty) {
      throw Exception('Product ID not found for plan: ${plan.name}');
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product details for "$productId" not found.'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

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
          status: purchaseDetails.status,
          details: purchaseDetails,
          isAcknowledged: false,
          message: 'Verifying with server...',
        ));
        
        // CRITICAL: Verify with backend BEFORE completing
        bool verified = await _verifyPurchaseWithBackend(purchaseDetails);
        
        if (verified) {
          debugPrint('PlanService: 🎉 Backend verification SUCCESS');
          
          // CRITICAL: Complete the purchase on Google's side
          // This prevents duplicate purchase attempts
          if (purchaseDetails.pendingCompletePurchase) {
            debugPrint('PlanService: Completing purchase transaction...');
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          
          // Emit success result
          _purchaseResultController.add(PurchaseResult(
            status: purchaseDetails.status,
            details: purchaseDetails,
            isAcknowledged: true,
            message: 'Subscription activated successfully!',
          ));
          
          // Refresh subscription data
          await getCurrentSubscription();
          
        } else {
          debugPrint('PlanService: ❌ Backend verification FAILED. Starting retry...');
          
          // Start heartbeat retry mechanism
          startVerificationRetry(purchaseDetails);
          
          // Keep showing "Awaiting Confirmation" status
          _purchaseResultController.add(PurchaseResult(
            status: purchaseDetails.status,
            details: purchaseDetails,
            isAcknowledged: false,
            message: 'Server verification in progress...',
          ));
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

  /// Start a heartbeat that retries verification every 10 seconds
  static void startVerificationRetry(PurchaseDetails purchaseDetails) {
    stopHeartbeat(); // Clear any existing timer
    _heartbeatCount = 0;
    
    debugPrint('PlanService: 🫀 Starting verification retry heartbeat...');
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      _heartbeatCount++;
      debugPrint('PlanService: 🫀 Heartbeat #$_heartbeatCount - Retrying verification...');
      
      // Stop after 6 attempts (1 minute total)
      if (_heartbeatCount > 6) {
        debugPrint('PlanService: 🫀 Heartbeat timeout - stopping retries');
        stopHeartbeat();
        // Emit error state so the UI stops spinning
        _purchaseResultController.add(PurchaseResult(
          status: PurchaseStatus.error,
          details: purchaseDetails,
          message: 'Server verification is taking longer than expected. Please check your internet or try again later.',
        ));
        return;
      }
      
      // Retry verification with backend
      try {
        bool verified = await PlanService()._verifyPurchaseWithBackend(purchaseDetails);
        
        if (verified) {
          debugPrint('PlanService: 🫀 Heartbeat SUCCESS - Verification completed!');
          
          if (purchaseDetails.pendingCompletePurchase) {
            debugPrint('PlanService: Completing purchase transaction after retry...');
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
          
          // Emit the success update
          _purchaseResultController.add(PurchaseResult(
            status: purchaseDetails.status,
            details: purchaseDetails,
            isAcknowledged: true,
            message: 'Subscription activated successfully!',
          ));
          
          // Refresh subscription data
          final subscription = await PlanService().getCurrentSubscription();
          if (subscription != null) {
            notifySubscriptionChange(subscription);
          }
          
          stopHeartbeat();
        } else {
          debugPrint('PlanService: 🫀 Heartbeat - Verification failed, will retry...');
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

  Future<bool> _verifyPurchaseWithBackend(PurchaseDetails purchaseDetails) async {
    _log('Attempting server verification for: ${purchaseDetails.purchaseID}', isVerbose: true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$kAgentBaseUrl/google-billing/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
          'productId': purchaseDetails.productID,
        }),
      ).timeout(const Duration(seconds: 15));

      if (verboseLogging) {
        _log('Verification Status: ${response.statusCode}', isVerbose: true);
        _log('Verification Body: ${response.body}', isVerbose: true);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      _log('Network verification error', error: e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$kAgentBaseUrl/subscription/current'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final subData = data['data'];
          _cachedSubscription = subData as Map<String, dynamic>?;
          _checkAndStartMonitoring();
          notifySubscriptionChange(subData);
          return subData;
        }
      }
      return null;
    } catch (e) {
      debugPrint('getCurrentSubscription error: $e');
      return null;
    }
  }

  Future<List<AgentPlan>> fetchPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('$kAgentBaseUrl/plans'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> plansJson = data['data'];
        return plansJson.map((json) => AgentPlan.fromJson(json)).toList();
      }
    }
    throw Exception('Failed to load plans');
  }

  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$kAgentBaseUrl/subscription/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('getSubscriptionHistory error: $e');
      return [];
    }
  }

  Future<void> verifySubscription(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$kAgentBaseUrl/subscription/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'reference': reference}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Verification failed: ${response.body}');
    }
  }

  Future<double> fetchPlatformFee() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/general/platform-fee'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']['platform_fee'] as num).toDouble();
        }
      }
      return 300.0; // Default fallback
    } catch (e) {
      debugPrint('Error fetching platform fee: $e');
      return 300.0; // Default fallback
    }
  }
}

class PurchaseResult {
  final PurchaseStatus status;
  final PurchaseDetails? details;
  final String? message;
  final bool isAcknowledged;

  PurchaseResult({
    required this.status,
    this.details,
    this.message,
    this.isAcknowledged = false,
  });
}
