import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/models/agent_plan.dart';

/// Shows a checkout bottom sheet with payment method selection.
void showCheckoutSheet({
  required BuildContext context,
  required AgentPlan plan,
  required VoidCallback onPayWithGoogle,
  double platformFee = 300.0,
}) {
  final double total = plan.price + platformFee;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Checkout Summary',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _buildBreakdownRow('Plan (${plan.name})',
                    '₦ ${plan.price.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildBreakdownRow(
                    'Platform Fee', '₦ ${platformFee.toStringAsFixed(2)}'),
                const Divider(height: 24),
                _buildBreakdownRow(
                    'Total Amount', '₦ ${total.toStringAsFixed(2)}',
                    isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PAYMENT METHOD',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kGrey600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Pay with Google Play Button
          PaymentOptionButton(
            icon: Icons.credit_card,
            title: 'Google Play Billing',
            subtitle: 'Secure payment via Google Play Store',
            isEnabled: true,
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              onPayWithGoogle();
            },
          ),
          const SizedBox(height: 20),
          Text(
            '* Subscriptions are handled exclusively via Google Play Store to comply with store policies.',
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: kGrey500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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

/// A button for selecting a payment method.
class PaymentOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const PaymentOptionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    this.isPrimary = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isEnabled
              ? (isPrimary
                  ? kPrimaryColor
                  : kPrimaryColor.withValues(alpha: 0.05))
              : kGrey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? (isPrimary
                    ? kPrimaryColor
                    : kPrimaryColor.withValues(alpha: 0.3))
                : kGrey300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEnabled
                    ? (isPrimary
                        ? kWhite.withValues(alpha: 0.2)
                        : kPrimaryColor.withValues(alpha: 0.1))
                    : kGrey200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isEnabled ? (isPrimary ? kWhite : kPrimaryColor) : kGrey400,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? (isPrimary ? kWhite : kBlack87)
                          : kGrey500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: isEnabled
                          ? (isPrimary
                              ? kWhite.withValues(alpha: 0.8)
                              : kGrey600)
                          : kGrey400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color:
                  isEnabled ? (isPrimary ? kWhite : kPrimaryColor) : kGrey300,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
