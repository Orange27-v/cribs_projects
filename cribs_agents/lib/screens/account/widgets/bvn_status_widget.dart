import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class BvnStatusWidget extends StatelessWidget {
  final Map<String, dynamic> responsePayload;
  final VoidCallback? onRetry;

  const BvnStatusWidget({
    super.key,
    required this.responsePayload,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Handle the actual backend response structure
    final String status = responsePayload['status'] ?? 'failed';
    final String message =
        responsePayload['message'] ?? 'BVN verification status unknown.';

    IconData icon;
    Color iconColor;
    String displayStatus;
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'verified':
        icon = Icons.verified_user;
        iconColor = Colors.green;
        displayStatus = 'Verified';
        statusColor = Colors.green;
        break;
      case 'failed':
        icon = Icons.error;
        iconColor = Colors.red;
        displayStatus = 'Failed';
        statusColor = Colors.red;
        break;
      case 'pending':
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange;
        displayStatus = 'Pending';
        statusColor = Colors.orange;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
        displayStatus = 'Unknown';
        statusColor = Colors.grey;
        break;
    }

    return CardContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          status.toLowerCase() == 'verified'
              ? SvgPicture.asset(
                  'assets/icons/success.svg',
                  height: kIconSize80,
                  width: kIconSize80,
                )
              : Icon(icon, size: kIconSize80, color: iconColor),
          const SizedBox(height: kSizedBoxH24),
          Text(
            'BVN Verification Status: $displayStatus',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: kFontSize16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: kSizedBoxH16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: kFontSize14,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 32),
          if (status.toLowerCase() == 'failed' && onRetry != null)
            PrimaryButton(
              text: 'Retry Verification',
              onPressed: onRetry,
            ),
          if (status.toLowerCase() == 'verified')
            PrimaryButton(
              text: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}
