import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/wallet_service.dart';
import 'package:cribs_agents/screens/plans/payment_result_screens.dart'; // Reuse Failure Screen
import 'package:google_fonts/google_fonts.dart';

class DepositPaymentWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const DepositPaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<DepositPaymentWebViewScreen> createState() =>
      _DepositPaymentWebViewScreenState();
}

class _DepositPaymentWebViewScreenState
    extends State<DepositPaymentWebViewScreen> {
  late final WebViewController _controller;
  final WalletService _walletService = WalletService();
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
      debugPrint('Verifying deposit with backend: ${widget.reference}');

      // Verify with backend
      final result = await _walletService.verifyDeposit(widget.reference);

      if (!mounted) return;

      if (result['success'] == true) {
        debugPrint('Verification successful!');
        // Payment verified successfully - navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DepositSuccessScreen()),
        );
      } else {
        throw Exception(result['message'] ?? 'Verification failed');
      }
    } catch (e) {
      debugPrint('Payment verification failed: $e');

      if (!mounted) return;

      // Verification failed - navigate to failure screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentFailureScreen(
            onRetry: () {
              // Go back to deposit screen to retry
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  void _handleClose() async {
    if (_isVerifying) return;

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Payment?'),
        content:
            const Text('If you have completed the payment, we will verify it. '
                'If not, your deposit will be cancelled.'),
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
      await _verifyPaymentAndNavigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Complete Deposit', style: TextStyle(color: kBlack87)),
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
                        'Verifying Deposit...',
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

class DepositSuccessScreen extends StatelessWidget {
  const DepositSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/success.svg',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 24),
            Text(
              'Deposit Successful!',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kBlack87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your wallet has been funded successfully.',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: kGrey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Go to Wallet',
              onPressed: () {
                // Return to wallet/profile by popping the success screen and deposit screen
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
