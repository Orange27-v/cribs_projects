import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/models/agent_plan.dart';
import 'package:cribs_agents/services/plan_service.dart';
import 'package:cribs_agents/screens/plans/widget/plan_card.dart';
import 'package:cribs_agents/screens/plans/widget/checkout_sheet.dart';
import 'package:cribs_agents/screens/plans/widget/subscription_info_modal.dart';
import 'package:cribs_agents/screens/plans/widget/active_subscription_banner.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cribs_agents/screens/plans/billing_status_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late Future<List<AgentPlan>> _plansFuture;
  final PlanService _planService = PlanService();
  Map<String, dynamic>? _currentSubscription;
  bool _isLoadingSubscription = true;
  bool _isStatusScreenOpen = false;
  double _platformFee = 300.0;

  StreamSubscription<Map<String, dynamic>?>? _streamSubscription;
  StreamSubscription<PurchaseResult>? _purchaseResultSubscription;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _purchaseResultSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _plansFuture = _planService.fetchPlans();
      _isLoadingSubscription = true;
    });

    // Listen to live stream updates
    _streamSubscription = PlanService.subscriptionStream.listen((subscription) {
      if (mounted) {
        debugPrint('PlansScreen: Received stream update: $subscription');
        setState(() {
          _currentSubscription = subscription;
          _isLoadingSubscription = false;
        });
      }
    });

    // Handle purchase results (Navigation to Status Screen)
    _purchaseResultSubscription =
        PlanService.purchaseResultStream.listen((result) {
      if (mounted) {
        debugPrint('PlansScreen: Purchase result received: ${result.status}');
        
        // Don't show status screen for cancellations unless specifically requested, 
        // but for Success, Error, and Pending, it's very helpful.
        // Navigation Logic: Only push if not already on the status screen
        if (result.status != PurchaseStatus.canceled && !_isStatusScreenOpen) {
          _isStatusScreenOpen = true;
          debugPrint('PlansScreen: Pushing BillingStatusScreen...');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillingStatusScreen(result: result),
            ),
          ).then((_) {
            // Reset flag when screen is popped
            _isStatusScreenOpen = false;
            debugPrint('PlansScreen: BillingStatusScreen closed.');
          });
        }
      }
    });

    // Fetch current subscription (will trigger stream too)
    try {
      final subscription = await _planService.getCurrentSubscription();
      // _currentSubscription acts as initial state, but stream will keep it fresh
      if (mounted && _currentSubscription == null) {
        setState(() {
          _currentSubscription = subscription;
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching current subscription: $e');
      if (mounted) {
        setState(() => _isLoadingSubscription = false);
      }
    }


    // Fetch platform fee
    try {
      final fee = await _planService.fetchPlatformFee();
      if (mounted) {
        setState(() => _platformFee = fee);
      }
      debugPrint('Platform fee loaded: $_platformFee');
    } catch (e) {
      debugPrint('Error fetching platform fee: $e');
    }

    // Initialize Google Play Billing
    try {
      await _planService.initializeInAppPurchase();
      if (mounted) {
        setState(() {}); // Rebuild to refresh IAP status if needed
      }
    } catch (e) {
      debugPrint('Error initializing IAP: $e');
    }
  }

  // Subscription getters
  bool get hasActiveSubscription {
    if (_currentSubscription == null) return false;
    final status = _currentSubscription!['status'];
    if (status == null) return false;
    if (status.toString().toLowerCase() != 'active') return false;

    final endDateStr = _currentSubscription!['end_date'];
    if (endDateStr != null) {
      try {
        final endDate = DateTime.parse(endDateStr);
        if (endDate.isBefore(DateTime.now())) return false;
      } catch (e) {
        debugPrint('Error parsing end_date: $e');
      }
    }
    return true;
  }

  int? get currentPlanId {
    if (_currentSubscription == null) return null;
    final planId = _currentSubscription!['plan_id'];
    if (planId == null) return null;
    if (planId is int) return planId;
    if (planId is String) {
      try {
        return int.parse(planId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? get subscribedPlanName => _currentSubscription?['plan_name'];
  String? get subscriptionStartDate => _currentSubscription?['start_date'];
  String? get subscriptionEndDate => _currentSubscription?['end_date'];

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        title: Text(
          'SUBSCRIPTION PLANS',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kBlack87,
          ),
        ),
        centerTitle: true,
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBlack87),
        actions: [
          IconButton(
            onPressed: _restorePurchases,
            icon: const Icon(Icons.restore, size: 20),
            tooltip: 'Restore Purchases',
          ),
          if (_isLoadingSubscription)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CustomLoadingIndicator(
                size: 20,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<AgentPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CustomLoadingIndicator(size: 45),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final plans = snapshot.data!;
          return _buildPlansList(plans);
        },
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return CustomRefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: kRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load plans: $error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: kBlack87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _loadData,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomRefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: const Center(child: Text('No plans available.')),
        ),
      ),
    );
  }

  Widget _buildPlansList(List<AgentPlan> plans) {
    return CustomRefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Show subscription info banner if active
            if (hasActiveSubscription) ...[
              ActiveSubscriptionBanner(
                planName: subscribedPlanName,
                expiryDate: subscriptionEndDate != null
                    ? _formatDate(subscriptionEndDate!)
                    : null,
              ),
              const SizedBox(height: 20),
            ],
            // Plan cards
            for (final plan in plans) ...[
              PlanCard(
                plan: plan,
                isPopular: plan.name == 'Standard',
                color: kPrimaryColor,
                isCurrentPlan: currentPlanId == plan.id,
                hasActiveSubscription: hasActiveSubscription,
                subscriptionEndDate: subscriptionEndDate,
                onSubscribe: () => _showCheckout(plan),
                onViewSubscription: () => _showSubscriptionInfo(),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  void _showSubscriptionInfo() {
    showSubscriptionInfoModal(
      context: context,
      planName: subscribedPlanName,
      startDate: subscriptionStartDate,
      endDate: subscriptionEndDate,
    );
  }

  void _showCheckout(AgentPlan plan) {
    showCheckoutSheet(
      context: context,
      plan: plan,
      platformFee: _platformFee,
      onPayWithGoogle: () => _subscribeWithGoogle(plan),
    );
  }



  bool _isIapBusy = false;

  Future<void> _restorePurchases() async {
    if (_isIapBusy) return;

    setState(() => _isIapBusy = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking Google Play for past purchases...'),
          duration: Duration(seconds: 2),
        ),
      );
      await _planService.restorePurchases();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isIapBusy = false);
      }
    }
  }

  Future<void> _subscribeWithGoogle(AgentPlan plan) async {
    if (_isIapBusy) return;
    
    setState(() => _isIapBusy = true);
    
    try {
      // If store is still initializing, this will wait automatically
      await _planService.buySubscription(plan);
      // Actual success handling is done via the purchase stream in PlanService
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: kRed,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(label: 'OK', textColor: kWhite, onPressed: () {}),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isIapBusy = false);
      }
    }
  }
}
