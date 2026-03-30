import 'package:cribs_agents/screens/account/nin_screens/nin_verification_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class NinVerificationScreen extends StatelessWidget {
  const NinVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('NIN VERIFICATION'),
      ),
      body: Padding(
        padding: kPaddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify your identity using your National Identification Number.',
              style: TextStyle(fontSize: 16, color: kGrey),
            ),
            const SizedBox(height: 24),
            OptionTile(
              svgPath:
                  'assets/icons/check_verified.svg', // Placeholder SVG path
              title: 'NIN Verification',
              subtitle: 'Verify using your National Identification Number',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NinVerificationDetailsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
