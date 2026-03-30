import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';

class PaymentWidget extends StatefulWidget {
  final int payeeId;
  final String agentName;
  final String agentImageUrl;
  final double bookingFee;
  final double platformFee;

  const PaymentWidget({
    super.key,
    required this.payeeId,
    required this.agentName,
    required this.agentImageUrl,
    required this.bookingFee,
    required this.platformFee,
  });

  @override
  State<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends State<PaymentWidget> {
  @override
  Widget build(BuildContext context) {
    final total = widget.bookingFee + widget.platformFee;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildBreakdownRow(
                    'Inspection Fee',
                    '₦ ${widget.bookingFee.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    'Platform Fee',
                    '₦ ${widget.platformFee.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _buildBreakdownRow(
                    'Total Amount',
                    '₦ ${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value,
      {bool isNegative = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: isTotal ? kPrimaryColor : kGrey600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isNegative ? Colors.red : (isTotal ? kPrimaryColor : kBlack),
          ),
        ),
      ],
    );
  }
}
