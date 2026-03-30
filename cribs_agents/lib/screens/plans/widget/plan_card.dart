import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/models/agent_plan.dart';
import 'package:intl/intl.dart';

/// A card widget that displays a subscription plan with its details and features.
class PlanCard extends StatelessWidget {
  final AgentPlan plan;
  final bool isPopular;
  final Color color;
  final bool isCurrentPlan;
  final bool hasActiveSubscription;
  final String? subscriptionEndDate;
  final VoidCallback? onSubscribe;
  final VoidCallback? onViewSubscription;

  const PlanCard({
    super.key,
    required this.plan,
    this.isPopular = false,
    this.color = kPrimaryColor,
    this.isCurrentPlan = false,
    this.hasActiveSubscription = false,
    this.subscriptionEndDate,
    this.onSubscribe,
    this.onViewSubscription,
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
    final currencyFormatter =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            border: isCurrentPlan
                ? Border.all(color: kGreen, width: 2)
                : isPopular
                    ? Border.all(color: color, width: 2)
                    : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrentPlan
                      ? kGreen.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCurrentPlan ? kGreen : color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currencyFormatter.format(plan.price),
                            style: GoogleFonts.roboto(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: kBlack87,
                            ),
                          ),
                          TextSpan(
                            text: '/month',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: kGrey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: kGrey600,
                      ),
                    ),
                    // Show expiry date if this is the current plan
                    if (isCurrentPlan && subscriptionEndDate != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: kGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Expires: ${_formatDate(subscriptionEndDate!)}',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: kGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Features section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (plan.features.isNotEmpty)
                      ...plan.features.map((feature) => FeatureItem(
                          feature: feature,
                          color: isCurrentPlan ? kGreen : color)),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: hasActiveSubscription
                          ? (isCurrentPlan
                              ? '✓ Current Plan'
                              : 'View Subscription')
                          : 'Subscribe',
                      backgroundColor: isCurrentPlan
                          ? kGreen
                          : hasActiveSubscription
                              ? kGrey400
                              : color,
                      onPressed: hasActiveSubscription
                          ? onViewSubscription
                          : onSubscribe,
                    ),
                    if (hasActiveSubscription && !isCurrentPlan) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Complete current subscription first',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: kGrey500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Current Plan badge
        if (isCurrentPlan)
          Positioned(
            top: -12,
            right: 0,
            left: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: kGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CURRENT PLAN',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kWhite,
                  ),
                ),
              ),
            ),
          )
        // Most Popular badge (only show if not current plan)
        else if (isPopular)
          Positioned(
            top: -12,
            right: 0,
            left: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kWhite,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A widget that displays a feature item with a checkmark icon.
class FeatureItem extends StatelessWidget {
  final String feature;
  final Color color;

  const FeatureItem({
    super.key,
    required this.feature,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kGrey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: color, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feature,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kBlack87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
