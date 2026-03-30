import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/rate_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:intl/intl.dart';

class SetRateScreen extends StatefulWidget {
  const SetRateScreen({super.key});

  @override
  State<SetRateScreen> createState() => _SetRateScreenState();
}

class _SetRateScreenState extends State<SetRateScreen> {
  final RateService _rateService = RateService();
  final TextEditingController _amountController = TextEditingController(
    text: "0.00",
  );

  bool _isLoading = true;
  bool _isSaving = false;
  double _currentBookingFees = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBookingFees();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Fetch the current booking fees from the server
  Future<void> _fetchCurrentBookingFees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _rateService.getBookingFees();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _currentBookingFees = result['booking_fees'] ?? 0.0;
          _amountController.text = _currentBookingFees.toStringAsFixed(2);
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  /// Save the booking fees to the server
  Future<void> _saveBookingFees() async {
    // Parse the amount from the text field
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));

    if (amount == null || amount < 0) {
      _showSnackBar('Please enter a valid amount', isError: true);
      return;
    }

    if (amount > 10000) {
      _showSnackBar('Maximum booking fee is ₦10,000', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await _rateService.setBookingFees(amount);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (result['success'] == true) {
          _currentBookingFees = result['booking_fees'] ?? amount;
          _amountController.text = _currentBookingFees.toStringAsFixed(2);
          _showSnackBar('Booking fees updated successfully!', isError: false);
        } else {
          _showSnackBar(result['message'] ?? 'Failed to update booking fees',
              isError: true);
        }
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Format currency for display
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Set Rate',
          style: GoogleFonts.roboto(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Current booking fees card
                      _buildCurrentRateCard(),
                      const SizedBox(height: 32),
                      // Set rate widget
                      Expanded(
                        child: _buildSetRateWidget(),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: PrimaryButton(
                text: _isSaving ? 'Saving...' : 'Confirm',
                onPressed: _isSaving ? null : _saveBookingFees,
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading booking fees',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCurrentBookingFees,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.price_change_outlined,
                  color: kWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Inspection Rate',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kWhite.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatCurrency(_currentBookingFees),
            style: GoogleFonts.roboto(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: kWhite,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'per property inspection',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: kWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRateWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Set your inspection rate',
          style: GoogleFonts.roboto(color: kGrey, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₦',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextFormField(
                controller: _amountController,
                textAlign: TextAlign.start,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Maximum: ₦10,000',
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: kGrey.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
