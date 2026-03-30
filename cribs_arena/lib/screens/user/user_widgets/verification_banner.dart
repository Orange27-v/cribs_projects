import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/screens/account/nin_screens/nin_verification_details_screen.dart';
import 'package:cribs_arena/screens/account/bvn_verification_screen.dart';
import 'dart:async';

class VerificationBanner extends StatefulWidget {
  const VerificationBanner({super.key});

  @override
  State<VerificationBanner> createState() => _VerificationBannerState();
}

class _VerificationBannerState extends State<VerificationBanner> {
  bool _isDismissed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismissBanner() {
    setState(() {
      _isDismissed = true;
    });

    // Set a timer to show the banner again after 5 minutes
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _isDismissed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // Check verification status
    // Database fields: nin_verification and bvn_verification are integers (0 = not verified, 1 = verified)
    final bool isNinVerified = (user?['nin_verification'] ?? 0) == 1;
    final bool isBvnVerified = (user?['bvn_verification'] ?? 0) == 1;

    // If both are verified, don't show the banner
    if (isNinVerified && isBvnVerified) {
      return const SizedBox.shrink();
    }

    // Determine the message based on verification status
    String message;
    if (!isNinVerified && !isBvnVerified) {
      message =
          'Verify your NIN and BVN to unlock all features and gain trust from agents';
    } else if (isNinVerified && !isBvnVerified) {
      message =
          'Great! Your NIN is verified. Now verify your BVN to complete your profile';
    } else {
      message =
          'Verify your BVN and NIN to unlock all features and gain trust from agents';
    }

    return GestureDetector(
      onTap: () {
        // Navigate to appropriate verification screen
        if (!isNinVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NinVerificationDetailsScreen(),
            ),
          );
        } else if (!isBvnVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BvnVerificationScreen(),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: kSizedBoxH16, vertical: kSizedBoxH8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kLightBlue.withValues(alpha: 0.1),
              kPrimaryColor.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: kRadius8,
          border: Border.all(
            color: kLightBlue.withValues(alpha: 0.3),
            width: kStrokeWidth1_5,
          ),
        ),
        child: ClipRRect(
          borderRadius: kRadius8,
          child: SizedBox(
            height: 25,
            child: Row(
              children: [
                // Verification Icon
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: kLightBlue.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: kPrimaryColor,
                    size: 16,
                  ),
                ),
                // Marquee Text
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kSizedBoxH8),
                    child: Marquee(
                      text: message,
                      style: const TextStyle(
                        fontSize: kFontSize10,
                        fontWeight: FontWeight.w500,
                        color: kPrimaryColor,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      blankSpace: kSizedBoxW50,
                      velocity: 30.0,
                      pauseAfterRound: const Duration(seconds: 2),
                      startPadding: kSizedBoxW10,
                      accelerationDuration: const Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: const Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                ),
                // Dismiss Button
                GestureDetector(
                  onTap: _dismissBanner,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: kPrimaryColor,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
