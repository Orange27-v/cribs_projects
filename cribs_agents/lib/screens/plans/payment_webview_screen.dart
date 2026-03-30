import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/plan_service.dart';
import 'package:cribs_agents/screens/plans/payment_result_screens.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  final PlanService _planService = PlanService();
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(kWhite)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WebView Page Started: $url');
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            debugPrint('WebView Page Finished: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            debugPrint('WebView Navigation Request: $url');

            // Check for Paystack close/success indicators
            if (url.contains('close') ||
                url.contains('status=success') ||
                url.contains('standard.paystack.co/close') ||
                url.contains('callback')) {
              // Payment completed - verify with backend
              _verifyPaymentAndNavigate();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  Future<void> _verifyPaymentAndNavigate() async {
    if (_isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      debugPrint('Verifying payment with backend: ${widget.reference}');

      // Verify with backend
      await _planService.verifySubscription(widget.reference);

      debugPrint('Verification successful!');

      if (!mounted) return;

      // Payment verified successfully - navigate to success screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
      );
    } catch (e) {
      debugPrint('Payment verification failed: $e');

      if (!mounted) return;

      // Verification failed - navigate to failure screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentFailureScreen(
            onRetry: () {
              // Go back to plans screen to retry
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  void _handleClose() async {
    // When user presses close, verify payment status with backend
    // (in case they completed payment but URL detection didn't work)

    if (_isVerifying) return;

    // Show confirmation dialog
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Payment?'),
        content:
            const Text('If you have completed the payment, we will verify it. '
                'If not, your payment will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify & Close'),
          ),
        ],
      ),
    );

    if (shouldClose == true && mounted) {
      // Try to verify - if payment was made, it will succeed
      await _verifyPaymentAndNavigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Complete Payment', style: TextStyle(color: kBlack87)),
        backgroundColor: kWhite,
        iconTheme: const IconThemeData(color: kBlack87),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleClose,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isVerifying)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomLoadingIndicator(
                        size: 40, color: kPrimaryColor),
                    if (_isVerifying) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Verifying Payment...',
                        style: TextStyle(
                          color: kBlack87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
