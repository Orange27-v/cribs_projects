import 'dart:convert';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/services/review_service.dart';
import 'package:cribs_arena/utils/error_handler.dart';

class ReviewScreen extends StatefulWidget {
  final String agentId;
  final String agentName;
  const ReviewScreen(
      {super.key, required this.agentId, required this.agentName});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _NoUrlOrPhoneNumberFormatter extends TextInputFormatter {
  // Regex to detect common URL patterns
  static final RegExp _urlRegex = RegExp(
    r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
    caseSensitive: false,
  );

  // Regex to detect common phone number patterns (simplified for this context)
  // This regex looks for sequences of 7 or more digits, possibly with spaces, hyphens, or parentheses.
  static final RegExp _phoneRegex = RegExp(
    r'(\+\d{1,3}[- ]?)?(\(?\d{3}\)?[- ]?){2}\d{4,}',
  );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isNotEmpty) {
      if (_urlRegex.hasMatch(newValue.text) ||
          _phoneRegex.hasMatch(newValue.text)) {
        // If a URL or phone number is detected, revert to the old value
        return oldValue;
      }
    }
    return newValue;
  }
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  final _reviewService = ReviewService();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    final reviewText = _reviewController.text;
    if (_NoUrlOrPhoneNumberFormatter._urlRegex.hasMatch(reviewText) ||
        _NoUrlOrPhoneNumberFormatter._phoneRegex.hasMatch(reviewText)) {
      SnackbarHelper.showError(
          context, 'Review cannot contain URLs or phone numbers.',
          position: FlashPosition.bottom);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final navigator = Navigator.of(context);

    try {
      final response = await _reviewService.submitReview(
        agentId: int.parse(widget.agentId),
        rating: _rating,
        reviewText: reviewText,
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        SnackbarHelper.showSuccess(context, 'Review submitted successfully.',
            position: FlashPosition.bottom);
        navigator.pop();
      } else {
        String errorMessage = 'Failed to submit review.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = 'Failed to submit review: ${errorBody['message']}';
          }
        } catch (_) {
          // The response body was not a parsable JSON, so we use the generic message.
        }
        SnackbarHelper.showError(context, errorMessage,
            position: FlashPosition.bottom);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kBlack87, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Rate ${widget.agentName}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rate the experience',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: kGrey,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: kPrimaryColor,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Text(
                  'How would you describe the experience',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: kBlack87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  inputFormatters: [
                    _NoUrlOrPhoneNumberFormatter(),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: kGrey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: kRadius12,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: kPaddingAll16,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    minimumSize: const Size(double.infinity, kSizedBoxH48),
                    shape: RoundedRectangleBorder(
                      borderRadius: kRadius30,
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize14,
                      fontWeight: FontWeight.w500,
                      color: kWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSubmitting)
            const SimpleLoadingOverlay(message: 'Submitting review...'),
        ],
      ),
    );
  }
}
