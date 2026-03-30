import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  // Fired INSTANTLY when URL match is found (starts background work)
  final VoidCallback onPaymentDetected;
  // Fired if user manually cancels
  final VoidCallback onCancel;

  const PaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.onPaymentDetected,
    required this.onCancel,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentDetected = false;

  // New flag to control popping
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => _checkPaymentStatus(url),
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            _checkPaymentStatus(url);
            _injectPageHandlers();
          },
          onNavigationRequest: (NavigationRequest request) {
            _checkPaymentStatus(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterPaymentChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'PAYMENT_CANCELLED' && !_paymentDetected) {
            _handleManualClose();
          } else if (message.message == 'PAYMENT_SUCCESS' &&
              !_paymentDetected) {
            _handleSuccess();
          }
        },
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _injectPageHandlers() {
    _controller.runJavaScript('''
      (function() {
        if (window.flutterPaymentHandlerInstalled) return;
        window.flutterPaymentHandlerInstalled = true;
        
        // 1. Listener for Cancel/Close Buttons
        document.addEventListener('click', function(e) {
          var target = e.target;
          var text = (target.textContent || '').toLowerCase();
          if (text.includes('cancel') || text.includes('close')) {
            FlutterPaymentChannel.postMessage('PAYMENT_CANCELLED');
          }
        }, true);

        // 2. Interval to detect "Success" text if URL doesn't change
        setInterval(function() {
          var bodyText = document.body.innerText.toLowerCase();
          if (bodyText.includes('payment successful') || 
              bodyText.includes('transaction successful') || 
              bodyText.includes('sucessful') // common typo coverage
             ) {
             FlutterPaymentChannel.postMessage('PAYMENT_SUCCESS');
          }
        }, 1000);
      })();
    ''');
  }

  void _checkPaymentStatus(String url) {
    if (_paymentDetected) return;

    final uri = Uri.parse(url);
    final queryParams = uri.queryParameters;

    final bool hasSuccessStatus =
        url.contains('status=success') || queryParams['status'] == 'success';
    final bool hasTrxRef =
        url.contains('trxref=') || queryParams.containsKey('trxref');
    final bool hasReference =
        url.contains('reference=') || queryParams.containsKey('reference');
    final bool hasClose = url.contains('/close');

    // Strict validation
    String? detectedRef = queryParams['reference'] ?? queryParams['trxref'];
    bool isRefMatch =
        (detectedRef == null) || (detectedRef == widget.reference);
    if (url.contains(widget.reference)) isRefMatch = true;

    if ((hasSuccessStatus || hasTrxRef || hasReference || hasClose) &&
        isRefMatch) {
      _handleSuccess();
    }
  }

  void _handleSuccess() async {
    if (_paymentDetected) return; // Prevent multiple triggers
    _paymentDetected = true;
    debugPrint('🚀 Success detected! Notifying parent immediately...');

    // 1. Notify BookingScreen INSTANTLY to start backend verification
    widget.onPaymentDetected();

    // 2. Wait for Paystack animation (The user enjoys the green checkmark)
    await Future.delayed(const Duration(seconds: 3));

    // 3. Close WebView
    if (mounted) {
      debugPrint(' Animation done. Popping WebView.');

      // CRITICAL FIX: Set canPop = true
      setState(() => _canPop = true);

      // Wait for frame to rebuild so PopScope sees the new 'true' value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _handleManualClose() {
    // If user clicks X, we allow the pop
    if (!_paymentDetected) {
      widget.onCancel();
    }
    setState(() => _canPop = true);
    // Wait for frame rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using PopScope with the dynamic _canPop flag
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // If system back button was pressed, we handle it manually
        _handleManualClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PrimaryAppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: kPrimaryColor),
            onPressed: _handleManualClose,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CustomLoadingIndicator()),
          ],
        ),
      ),
    );
  }
}
