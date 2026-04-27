import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/services/plan_service.dart';
import 'dart:async';

class BillingStatusScreen extends StatefulWidget {
  final PurchaseResult result;

  const BillingStatusScreen({super.key, required this.result});

  @override
  State<BillingStatusScreen> createState() => _BillingStatusScreenState();
}

class _BillingStatusScreenState extends State<BillingStatusScreen> {
  late PurchaseResult _currentResult;
  StreamSubscription? _resultListener;

  @override
  void initState() {
    super.initState();
    _currentResult = widget.result;

    // If we are awaiting confirmation, listen for the auto-fix (heartbeat)
    if (_currentResult.status == PurchaseStatus.purchased &&
        !_currentResult.isAcknowledged) {
      // Listen to purchase results for heartbeat success or timeout error
      _resultListener = PlanService.purchaseResultStream.listen((res) {
        if (res.details?.purchaseID == _currentResult.details?.purchaseID) {
          if (res.isAcknowledged || res.status == PurchaseStatus.error) {
            debugPrint('BillingStatusScreen: 🎉 Sync state update detected! Status: ${res.status}');
            if (mounted) {
              setState(() {
                _currentResult = res;
              });
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _resultListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        title: Text(
          'PAYMENT STATUS',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kBlack87,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: kWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 32),
              _buildExplanationCard(),
              const SizedBox(height: 24),
              _buildDetailsCard(),
              const SizedBox(height: 48),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    IconData icon;
    Color color;
    String title;

    if (_currentResult.status == PurchaseStatus.purchased ||
        _currentResult.status == PurchaseStatus.restored) {
      if (_currentResult.isAcknowledged) {
        icon = Icons.check_circle_rounded;
        color = kPrimaryColor;
        title = 'Payment Successful';
      } else {
        // Show a spinner for Awaiting Confirmation state
        return Column(
          children: [
            const CustomLoadingIndicator(size: 80, strokeWidth: 4),
            const SizedBox(height: 16),
            Text(
              'Awaiting Confirmation',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kBlack87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
    } else if (_currentResult.status == PurchaseStatus.pending) {
      icon = Icons.hourglass_top_rounded;
      color = Colors.blue;
      title = 'Payment Pending';
    } else if (_currentResult.status == PurchaseStatus.error) {
      icon = Icons.error_rounded;
      color = kRed;
      title = 'Payment Failed';
    } else if (_currentResult.status == PurchaseStatus.canceled) {
      icon = Icons.cancel_rounded;
      color = kGrey600;
      title = 'Payment Cancelled';
    } else {
      icon = Icons.help_outline_rounded;
      color = kGrey500;
      title = 'Unknown Status';
    }

    return Column(
      children: [
        Icon(icon, size: 80, color: color),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kBlack87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExplanationCard() {
    String explanation;
    String? subTitle;

    if (_currentResult.status == PurchaseStatus.purchased ||
        _currentResult.status == PurchaseStatus.restored) {
      if (_currentResult.isAcknowledged) {
        explanation =
            'Your subscription has been successfully activated. You can now access all features of your selected plan immediately.';
      } else {
        explanation =
            'Your payment was successful, but our server hasn\'t finalized the handshake with Google Play yet.';
        subTitle =
            'Don\'t worry! This is normal. We will automatically retry in the background. Your plan will appear as "Active" shortly.\n\nTip: You can also pull down to refresh on the Plans screen to check again.';
      }
    } else if (_currentResult.status == PurchaseStatus.pending) {
      explanation =
          'Google is still processing your payment. This usually happens with slow bank responses or certain payment methods.';
      subTitle =
          'You can close this screen; your subscription will activate automatically once Google finishes processing.';
    } else if (_currentResult.status == PurchaseStatus.error) {
      explanation = _getReadableErrorMessage();
    } else if (_currentResult.status == PurchaseStatus.canceled) {
      explanation =
          'The transaction was cancelled. No charges were made to your Google Play account.';
    } else {
      explanation = 'Something went wrong. Please check your internet and try again.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            explanation,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: kBlack87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (subTitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subTitle,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: kGrey600,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final detailsView = _buildDetailRows();
    if (detailsView.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGrey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kGrey500,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ...detailsView,
        ],
      ),
    );
  }

  List<Widget> _buildDetailRows() {
    final List<Widget> rows = [];
    if (_currentResult.details == null) return rows;

    final purchase = _currentResult.details!;

    rows.add(_buildRow('Product ID', purchase.productID));
    if (purchase.purchaseID != null && purchase.purchaseID!.isNotEmpty) {
      rows.add(
          _buildRow('Transaction ID', purchase.purchaseID!, isCopyable: true));
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(purchase.transactionDate ?? '') ??
            DateTime.now().millisecondsSinceEpoch);
    rows.add(_buildRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(date)));

    return rows;
  }

  Widget _buildRow(String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: kGrey600),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kBlack87,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getReadableErrorMessage() {
    if (_currentResult.message != null && _currentResult.message!.isNotEmpty) {
      return _currentResult.message!;
    }
    
    if (_currentResult.details?.error == null) {
      return 'We encountered an issue verifying your payment. Please try again or contact support if the problem persists.';
    }

    final error = _currentResult.details!.error!;
    final code = error.code;
    final message = error.message.toLowerCase();

    // Check for specific developer errors often returned as text/messages
    if (message.contains('developererror') || code.contains('developer_error')) {
      return 'Technical Configuration Error. This usually happens if you already have an active or pending transaction for this plan on your Google account. Please wait a few minutes and try again.';
    }
    
    if (code == 'purchase_error') {
      return 'The Play Store encountered an issue processing this request. Please check your payment method and ensured you are signed into a valid tester account.';
    }

    // Google Play Billing Response Codes mapping
    switch (code) {
      case '1':
        return 'The payment was cancelled by you. No funds were deducted.';
      case '2':
        return 'The service is currently unavailable. This is usually due to poor internet.';
      case '3':
        return 'Billing is not supported for your Google account or region.';
      case '4':
        return 'The selected subscription plan is no longer available in the store.';
      case '5':
        return 'Technical Configuration Error. We were unable to initialize the purchase process.';
      case '6':
        return 'A general error occurred in the Play Store. Please check your payment method and try again.';
      case '7':
        return 'You already own an active subscription for this plan.';
      default:
        return 'Error: ${error.message} (Code: $code)';
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    if (_currentResult.status == PurchaseStatus.error ||
        _currentResult.status == PurchaseStatus.canceled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            text: 'Try Again',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back to Plans',
              style: GoogleFonts.roboto(color: kGrey600),
            ),
          ),
        ],
      );
    }

    return PrimaryButton(
      text: _currentResult.isAcknowledged ? 'Start Listing' : 'Got it',
      onPressed: () {
        // Stop heartbeat if it's still running
        PlanService.stopHeartbeat();
        Navigator.pop(context);
      },
    );
  }
}
