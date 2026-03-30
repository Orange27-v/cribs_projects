import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class VninStatusWidget extends StatelessWidget {
  final Map<String, dynamic> responsePayload;
  final VoidCallback? onRetry;

  const VninStatusWidget({
    super.key,
    required this.responsePayload,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final String status =
        responsePayload['summary']['v_nin_check']['status'] ?? 'failed';
    final String message = responsePayload['summary']['v_nin_check']
            ['message'] ??
        'vNIN verification failed.';
    IconData icon;
    Color iconColor;
    String displayStatus;
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'exact_match':
        icon = Icons.verified_user;
        iconColor = Colors.green;
        displayStatus = 'Verified (Exact Match)';
        statusColor = Colors.green;
        break;
      case 'partial_match':
        icon = Icons.warning;
        iconColor = Colors.orange;
        displayStatus = 'Verified (Partial Match)';
        statusColor = Colors.orange;
        break;
      case 'no_match':
      case 'failed':
        icon = Icons.error;
        iconColor = Colors.red;
        displayStatus = 'Failed';
        statusColor = Colors.red;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
        displayStatus = 'Unknown Status';
        statusColor = Colors.grey;
        break;
    }

    return CardContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: kIconSize80, color: iconColor),
          const SizedBox(height: kSizedBoxH24),
          Text(
            'vNIN Verification Status: $displayStatus',
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
          if ((status.toLowerCase() == 'no_match' ||
                  status.toLowerCase() == 'failed') &&
              onRetry != null)
            PrimaryButton(
              text: 'Retry Verification',
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
