import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class PendingStatusWidget extends StatelessWidget {
  final String message;

  const PendingStatusWidget({
    super.key,
    this.message = 'Verification in progress. Please wait...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomLoadingIndicator(
            color: kPrimaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: kGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
