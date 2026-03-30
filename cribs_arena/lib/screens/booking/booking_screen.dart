import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flash/flash.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:cribs_arena/services/booking_service.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/services/property_tracking_service.dart';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:cribs_arena/screens/booking/calendar.dart';
import 'package:cribs_arena/screens/booking/timepicker.dart';
import 'package:cribs_arena/screens/booking/payment.dart';
import 'package:cribs_arena/screens/booking/booking_confirmation_screen.dart';
import 'package:cribs_arena/screens/booking/payment_webview_screen.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/helpers/chat_helper.dart';

class BookingScreen extends StatefulWidget {
  final Agent agent;
  final int? propertyDbId;

  const BookingScreen({
    super.key,
    required this.agent,
    this.propertyDbId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final PageController _pageController = PageController();
  final BookingService _bookingService = BookingService();
  final PropertyService _propertyService = PropertyService();
  final PropertyTrackingService _trackingService = PropertyTrackingService();

  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _propertyImageUrl;
  bool _isProcessingPayment = false;

  // Platform fee from backend
  double _platformFee = 700.0; // Default fallback value
  bool _isLoadingFee = true;

  // Track if we are currently running verification to prevent double calls
  bool _isVerifyingInBackground = false;

  @override
  void initState() {
    super.initState();
    _fetchPropertyDetails();
    _fetchPlatformFee();
  }

  Future<void> _fetchPlatformFee() async {
    try {
      final fee = await _bookingService.getPlatformFee();
      if (!mounted) return;
      setState(() {
        _platformFee = fee;
        _isLoadingFee = false;
      });
    } catch (e) {
      debugPrint('Platform fee fetch error: $e');
      // Keep the default fallback value
      if (mounted) {
        setState(() => _isLoadingFee = false);
      }
    }
  }

  Future<void> _fetchPropertyDetails() async {
    if (widget.propertyDbId == null) return;
    try {
      final property = await _propertyService
          .getPropertyDetails(widget.propertyDbId!.toString());
      if (!mounted) return;
      if (property.images.isNotEmpty) {
        setState(() => _propertyImageUrl = property.images[0]);
      }
    } catch (e) {
      debugPrint('Property fetch error: $e');
    }
  }

  double _bookingFee() {
    final fees = widget.agent.bookingFees;
    return (fees != null && fees > 0) ? fees : 1000.0;
  }

  String _formattedTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// This method is called INSTANTLY when Paystack says success.
  /// It runs in the background while the WebView is still open.
  Future<void> _verifyAndFinalizeBooking({
    required int agentId,
    required String reference,
    required DateTime date,
    required String formattedTime,
    required double amount,
  }) async {
    if (_isVerifyingInBackground) return;
    _isVerifyingInBackground = true;

    // Show loader on BookingScreen (it will be visible behind WebView or when WebView pops)
    if (mounted) setState(() => _isProcessingPayment = true);

    debugPrint('🔄 Background Verification Started...');
    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Wait a little on retries, but first attempt is immediate
        if (retryCount > 0) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        }

        final finalizeResponse = await _bookingService.finalizeBooking(
          agentId: agentId,
          propertyDbId: widget.propertyDbId,
          paystackReference: reference,
          inspectionDate: date.toIso8601String().split('T')[0],
          inspectionTime: formattedTime,
          amount: amount,
          paymentMethod: 'Paystack',
        );

        if (!mounted) return;

        if (finalizeResponse['message'] == 'Booking finalized successfully.') {
          debugPrint('✅ Background Verification Complete. Navigating...');

          // Track inspection booking for analytics
          if (widget.propertyDbId != null) {
            _trackingService
                .incrementInspectionBookingCount(
                  widget.propertyDbId.toString(),
                )
                .then(
                    (_) => debugPrint('✅ Inspection booking count incremented'))
                .catchError((e) {
              debugPrint('⚠️ Failed to increment inspection booking count: $e');
            });
          }

          // CRITICAL: Use pushAndRemoveUntil to clear the specific booking flow stack
          // This ensures we remove BookingScreen AND PaymentWebViewScreen (and any others)
          // and land cleanly on the ConfirmationScreen.
          // We keep the first route (likely Home/Dashboard) so the user can go "Back" to Home.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => BookingConfirmationScreen(
                agentName: widget.agent.fullName,
                agentImageUrl: widget.agent.profileImage,
                propertyImageUrl: _propertyImageUrl ?? '',
                selectedDate: date,
                formattedTime: formattedTime,
              ),
            ),
            (route) => false,
          );
          return;
        } else {
          // Retry logic for "transaction not found"
          if (finalizeResponse['message']
              .toString()
              .toLowerCase()
              .contains('not found')) {
            retryCount++;
            continue;
          }
          throw Exception(finalizeResponse['message']);
        }
      } catch (e) {
        if (e.toString().toLowerCase().contains('not found') &&
            retryCount < maxRetries - 1) {
          retryCount++;
          continue;
        }

        debugPrint('❌ Verification Failed: $e');
        if (mounted) {
          setState(() => _isProcessingPayment = false);
          _isVerifyingInBackground = false;
          // Note: If this fails while WebView is open, the Snackbar might be hidden
          // or show up when WebView closes.
          // Show specific error for debugging
          String errorMessage =
              e.toString().replaceAll('Exception:', '').trim();
          SnackbarHelper.showError(
            context,
            'Failed: $errorMessage', // Show real error
            position: FlashPosition.bottom,
          );
        }
        return;
      }
    }
  }

  Future<void> _startPayment() async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user?['id'] == null) {
        throw Exception('User not logged in');
      }

      final date = _selectedDate;
      final time = _selectedTime;
      if (date == null || time == null) {
        setState(() => _isProcessingPayment = false);
        SnackbarHelper.showError(context, 'Select date and time',
            position: FlashPosition.bottom);
        return;
      }

      final bookingFee = _bookingFee();
      final totalAmount = bookingFee + _platformFee;

      final formattedTimeStr = _formattedTime(time);
      final agentId = int.parse(widget.agent.agentId.toString());

      // 1. Initialize
      final initResponse = await _bookingService.initializePaystackTransaction(
        totalAmount, // Send total amount (Booking + Platform)
        userProvider.email,
        {
          'user_id': userProvider
              .user!['user_id'], // Changed: use user_id (bigint business ID)
          'agent_id': agentId,
          'property_id': widget.propertyDbId,
          'platform_fee': _platformFee, // Track platform fee component
        },
      );

      final authorizationUrl = initResponse['data']?['authorization_url'];
      final reference = initResponse['data']?['reference'];

      if (authorizationUrl == null) {
        throw Exception('Payment initialization failed');
      }

      if (!mounted) return;

      // 2. Open WebView
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            authorizationUrl: authorizationUrl,
            reference: reference,
            onPaymentDetected: () {
              // 3. START VERIFICATION IMMEDIATELY (in background)
              // Pass only the booking fee (agent's fee) - not platform fee
              // Platform fee is for organization only, not stored in user schedule
              _verifyAndFinalizeBooking(
                agentId: agentId,
                reference: reference,
                date: date,
                formattedTime: formattedTimeStr,
                amount: bookingFee, // Only agent's booking fee, not total
              );
            },
            onCancel: () {
              if (mounted) {
                setState(() => _isProcessingPayment = false);
                _isVerifyingInBackground = false;
              }
            },
          ),
        ),
      );

      // 4. When await Navigator.push returns, the WebView has popped.
      // If verification finished successfully, this screen is likely already replaced/disposed.
      // If not, the loader is still showing because we set _isProcessingPayment=true.
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        _isVerifyingInBackground = false;
        SnackbarHelper.showError(context, 'Error: $e',
            position: FlashPosition.bottom);
      }
    }
  }

  Widget buildStepper() {
    return Column(
      children: [
        Text(_stepTitle(), style: kBookingSubTitleStyle),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentStep == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentStep >= index
                    ? kPrimaryColor
                    : kPrimaryColor.withAlpha(128),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Date';
      case 1:
        return 'Select Time';
      case 2:
        return 'Checkout';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 120,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: kPrimaryColor),
          label: const Text('Cancel', style: kAppBarTextStyle),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: (widget.agent.profileImage.isNotEmpty)
                          ? NetworkImage(ChatHelper.getFullImageUrl(
                              widget.agent.profileImage))
                          : const AssetImage(
                                  'assets/images/default_profile.jpg')
                              as ImageProvider,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Book an Inspection with',
                    style: GoogleFonts.roboto(
                        color: kPrimaryColor.withValues(alpha: 0.8),
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(widget.agent.fullName, style: kBookingTitleStyle),
                const SizedBox(height: 32),
                buildStepper(),
                const SizedBox(height: 24),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.58,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentStep = page),
                    children: [
                      CalendarWidget(
                          onDateSelected: (d) =>
                              setState(() => _selectedDate = d)),
                      TimePickerWidget(
                          onTimeSelected: (t) =>
                              setState(() => _selectedTime = t)),
                      _isLoadingFee
                          ? const Center(child: CustomLoadingSpinner())
                          : PaymentWidget(
                              payeeId: widget.agent.id,
                              agentName: widget.agent.fullName,
                              agentImageUrl: widget.agent.profileImage,
                              bookingFee: _bookingFee(),
                              platformFee: _platformFee,
                            ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
              ],
            ),
          ),
          if (_isProcessingPayment)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomLoadingSpinner(
                      size: 50,
                      color: kPrimaryColor,
                      backgroundColor: kWhite,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Finalizing Booking...",
                      style: GoogleFonts.roboto(
                        color: kWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _currentStep == 2
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease),
                        style: OutlinedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16)),
                        child:
                            const Icon(Icons.arrow_back, color: kPrimaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isProcessingPayment ? null : _startPayment,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _isProcessingPayment
                                  ? kGrey400
                                  : kBookingButtonColor,
                              disabledBackgroundColor: kGrey400,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder()),
                          icon: _isProcessingPayment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CustomLoadingSpinner(
                                    size: 20,
                                    strokeWidth: 2,
                                    color: kWhite,
                                    backgroundColor: Colors.transparent,
                                  ),
                                )
                              : const Icon(Icons.payment, color: Colors.white),
                          label: Text(
                            _isProcessingPayment
                                ? "Payment Initiating..."
                                : "Tap to Pay",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: _currentStep == 0
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        FloatingActionButton(
                          onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease),
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.arrow_back,
                              color: kPrimaryColor),
                        ),
                      FloatingActionButton(
                        onPressed: () {
                          if (_currentStep < 2) {
                            _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease);
                          }
                        },
                        backgroundColor: kBookingButtonColor,
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
