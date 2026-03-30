import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Shows a modal bottom sheet with current subscription information.
void showSubscriptionInfoModal({
  required BuildContext context,
  required String? planName,
  required String? startDate,
  required String? endDate,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SubscriptionInfoContent(
      planName: planName,
      startDate: startDate,
      endDate: endDate,
    ),
  );
}

/// Content widget for the subscription info modal.
class SubscriptionInfoContent extends StatelessWidget {
  final String? planName;
  final String? startDate;
  final String? endDate;

  const SubscriptionInfoContent({
    super.key,
    this.planName,
    this.startDate,
    this.endDate,
  });

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
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/icons/success.svg',
              height: 40,
              width: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Active Subscription',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kBlack87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are subscribed to',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: kGrey600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            planName ?? 'Unknown Plan',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kGrey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start Date',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: kGrey600,
                      ),
                    ),
                    Text(
                      startDate != null ? _formatDate(startDate!) : 'N/A',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kBlack87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expiry Date',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: kGrey600,
                      ),
                    ),
                    Text(
                      endDate != null ? _formatDate(endDate!) : 'N/A',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You can subscribe to a new plan after your current subscription expires.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: kGrey500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Got it',
            backgroundColor: kPrimaryColor,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
