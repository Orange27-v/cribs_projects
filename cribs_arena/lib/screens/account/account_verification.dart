import 'package:cribs_arena/screens/account/bvn_verification_screen.dart';
import 'package:cribs_arena/screens/account/nin_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';

import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';

class AccountVerificationScreen extends StatelessWidget {
  const AccountVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('VERIFICATION'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          final isNinVerified = user != null && user['nin_verification'] == 1;
          final isBvnVerified = user != null && user['bvn_verification'] == 1;

          return Padding(
            padding: kPaddingAll16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OptionTile(
                  svgPath: 'assets/icons/shield_arrow.svg',
                  title: 'NIN Verification',
                  subtitle: isNinVerified
                      ? 'Your NIN is verified'
                      : 'Verify using NIN or vNIN',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NinVerificationScreen()),
                    );
                  },
                  trailing: isNinVerified
                      ? const VerifiedBadge()
                      : const Icon(Icons.arrow_forward_ios, color: kGrey),
                ),
                const SizedBox(height: kSizedBoxH12),
                OptionTile(
                  svgPath: 'assets/icons/finger_print.svg',
                  title: 'BVN Verification',
                  subtitle: isBvnVerified
                      ? 'Your BVN is verified'
                      : 'Verify using your BVN',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BvnVerificationScreen()),
                    );
                  },
                  trailing: isBvnVerified
                      ? const VerifiedBadge()
                      : const Icon(Icons.arrow_forward_ios, color: kGrey),
                ),
                const SizedBox(height: kSizedBoxH12),
                // const OptionTile(
                //   svgPath: 'assets/icons/face_id.svg',
                //   title: 'Face Verification',
                //   subtitle: 'Coming soon',
                //   onTap: null, // Disabled
                // ),
                // const SizedBox(height: kSizedBoxH12),
                // const OptionTile(
                //   svgPath: 'assets/icons/home.svg',
                //   title: 'Address Verification',
                //   subtitle: 'Coming soon',
                //   onTap: null, // Disabled
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
