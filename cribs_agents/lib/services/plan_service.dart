import 'dart:convert';
import 'dart:async';
import 'dart:io';
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

  /// Map Google Product IDs to internal Plan Names
  static const Map<String, String> productMappings = {
    'cribs_agent_basic': 'Starter',
    'cribs_agent_standard': 'Standard',
    'cribs_agent_premium': 'Premium',
  };

  /// Stream of subscription updates for real-time UI updates
  static Stream<Map<String, dynamic>?> get subscriptionStream =>
      _subscriptionController.stream;

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
          updatedSub['status'] = 'Expired'; // Or whatever status means expired

          // Notify (will update cache and stop timer via _checkAndStartMonitoring)
          notifySubscriptionChange(null); // Or send updated object?
          // Previous logic in screens seemed to treat null as expired/no-plan.
          // Let's stick to sending null for now to indicate "No Valid Active Plan".
          // Or we can send the expired object. PropertiesScreen handles both.
          // Let's send the object with "Expired" status if that's what backend returns,
          // but specifically here we detected it locally.
          // The PropertiesScreen checks `data == null` OR `isBefore(now)`.
          // So sending the same object is fine, the screen will re-eval date.
          // But to force a refresh visually, we should probably emit.

          _subscriptionController.add(
              _cachedSubscription); // Re-emit same data, screens will re-check date
        }
      } catch (e) {
        debugPrint('PlanService: Error parsing date in monitor: $e');
      }
    }
  }

  /// Dispose timer when app functionality might not need it (hard to call in static context, usually app lifecycle)
  static void dispose() {
    _monitorTimer?.cancel();
    _purchaseSubscription?.cancel();
    _subscriptionController.close();
  }

  /// Initialize In-App Purchases and load products
  Future<void> initializeInAppPurchase() async {
    debugPrint('PlanService: Initializing In-App Purchase...');
    
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('PlanService: Google Play Store NOT available on this device');
      return;
    }

    debugPrint('PlanService: Google Play Store is available');

    // Listen to purchase updates
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        debugPrint('PlanService: Received purchase updates: ${purchaseDetailsList.length} items');
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () => debugPrint('PlanService: Purchase stream closed'),
      onError: (error) => debugPrint('PlanService: Purchase stream error: $error'),
    );

    // Load products
    const Set<String> _kIds = {
      'cribs_agent_basic',
      'cribs_agent_standard',
      'cribs_agent_premium'
    };
    
    debugPrint('PlanService: Querying product details for: $_kIds');
    
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('PlanService: CRITICAL - Some products not found in Play Console: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      debugPrint('PlanService: ERROR querying products: ${response.error!.message}');
    }

    _products = response.productDetails;
    debugPrint('PlanService: Successfully loaded ${_products.length} products from Google');
    for (var product in _products) {
      debugPrint('PlanService: Found Product: ${product.id} - ${product.title} (${product.price})');
    }
  }

  /// Initiate a Google Play purchase
  Future<void> buySubscription(AgentPlan plan) async {
    // Find the product ID based on plan name or mapping
    final productId = productMappings.entries
        .firstWhere((entry) => entry.value == plan.name,
            orElse: () => const MapEntry('', ''))
        .key;

    if (productId.isEmpty) {
      throw Exception('Product ID not found for plan: ${plan.name}');
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception(
          'Product details not found for $productId in Google Play Store.\n\n'
          'Please ensure:\n'
          '1. The product ID is active in Play Console.\n'
          '2. You are using a licensed tester account.\n'
          '3. The app is signed correctly.'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading in UI?
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('PlanService: Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify with backend
        final bool valid = await _verifyGoogleSubscription(purchaseDetails);
        if (valid) {
          // Finalize purchase with Google
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      }
    }
  }

  Future<bool> _verifyGoogleSubscription(PurchaseDetails purchaseDetails) async {
    debugPrint('PlanService: Verifying Google Purchase: ${purchaseDetails.purchaseID}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$kAgentBaseUrl/subscription/verify-google'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
          'productId': purchaseDetails.productID,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('PlanService: Google Purchase Verified successfully');
          // Update local state
          getCurrentSubscription();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('PlanService: Verification Error: $e');
      return false;
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
      } else {
        throw Exception(data['message'] ?? 'Failed to load plans');
      }
    } else {
      throw Exception('Failed to load plans: ${response.statusCode}');
    }
  }

  /// Fetch the platform fee from the server
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

  Future<Map<String, dynamic>> initializeSubscription(int planId) async {
    debugPrint('PlanService: Initializing subscription for planId: $planId');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    final url = '$kAgentBaseUrl/subscription/initialize';
    debugPrint('PlanService: Request URL: $url');
    debugPrint('PlanService: Token present: ${token.isNotEmpty}');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'plan_id': planId}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('PlanService: Init Response Status: ${response.statusCode}');
      debugPrint('PlanService: Init Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']; // Contains authorization_url and reference
        } else {
          throw Exception(data['message'] ?? 'Payment initialization failed');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Validation error');
      } else {
        throw Exception(
            'Server error (${response.statusCode}). Please try again.');
      }
    } on TimeoutException {
      debugPrint('PlanService: Request timed out');
      rethrow;
    } on SocketException catch (e) {
      debugPrint('PlanService: Network error: $e');
      rethrow;
    } catch (e) {
      debugPrint('PlanService: Error: $e');
      rethrow;
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

      debugPrint(
          'getCurrentSubscription response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final subData = data['data'];
          _cachedSubscription = subData as Map<String, dynamic>?;
          _checkAndStartMonitoring();
          notifySubscriptionChange(
              subData); // Ensure stream is updated initially too
          return subData;
        }
      }
      return null;
    } catch (e) {
      debugPrint('getCurrentSubscription error: $e');
      return null;
    }
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

}
