import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/screens/components/custom_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of issues to be displayed
    final List<String> issues = [
      'No response or Ghosting',
      'Rude or unprofessional behavior',
      'Requests for additional payment',
      'Sexual harassment or Inappropriate behavior',
      'Inflated fees',
      'Bribery',
      'Bait-and-switch (property shown is different from the one listed)',
    ];

    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const CustomAppBar(
        title: 'Report Issue',
        showBackButton: true,
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oghenetejiri',
                        style: GoogleFonts.roboto(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: kFontSize22,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: kIconSize16,
                          ),
                          const SizedBox(width: kSizedBoxW4),
                          Text(
                            '4.9',
                            style: GoogleFonts.roboto(
                              color: kBlack87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• 50 reviews',
                            style: GoogleFonts.roboto(color: kGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: kSizedBoxW16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor.withValues(alpha: 0.1),
                    ),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/chat.svg',
                        colorFilter: const ColorFilter.mode(
                          kPrimaryColor,
                          BlendMode.srcIn,
                        ),
                        height: kIconSize24,
                        width: kIconSize24,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close report screen
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something is wrong? Choose an issue',
              style: GoogleFonts.roboto(
                fontSize: kFontSize20,
                fontWeight: FontWeight.bold,
                color: kBlack,
              ),
            ),
            const SizedBox(height: 24),
            // Build the list of reportable issues
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                return _buildIssueTile(
                  title: issues[index],
                  iconPath: 'assets/icons/block.svg',
                  onTap: () {
                    Navigator.of(context).pop(); // Close report screen
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
            const SizedBox(height: 16),
            // The "Other issues" option
            _buildIssueTile(
              title: 'Other issues',
              iconPath: 'assets/icons/block.svg',
              onTap: () {
                Navigator.of(context).pop(); // Close report screen
              },
            ),
          ],
        ),
      ),
    );
  }

  // Builds a single tappable tile for an issue
  Widget _buildIssueTile({
    required String title,
    required String iconPath,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            colorFilter: const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
            height: kIconSize24,
            width: kIconSize24,
          ),
          const SizedBox(width: kSizedBoxW16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: kFontSize16,
                color: kBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
