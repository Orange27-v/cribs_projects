import 'package:cribs_arena/provider/user_provider.dart'; // Import UserProvider
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:cribs_arena/sample_new_property_list_screen.dart';
import 'package:provider/provider.dart'; // Import Provider
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
// import 'package:firebase_messaging/firebase_messaging';
// import 'package:cribs_arena/screens/home/home_screen.dart';
import 'package:cribs_arena/screens/onboarding/onboarding_screen.dart';
import 'package:cribs_arena/screens/main_layout.dart';
// import 'package:cribs_arena/user_data_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import 'package:cribs_arena/services/user_auth_service.dart'; // Import AuthService
import 'package:cribs_arena/screens/auth/login_screen.dart'; // Import LoginScreen
import 'package:cribs_arena/screens/onboarding/permit_notification_screen.dart'; // Import PermitNotificationScreen
import 'package:cribs_arena/services/firebase_messaging_service.dart'; // Import FirebaseMessagingService
import 'package:cribs_arena/services/payment_service.dart';
import 'package:cribs_arena/main.dart'; // Import main.dart for global navigatorKey

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.8;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    // Fade in and zoom in (fast)
    setState(() {
      _opacity = 1.0;
      _scale = 1.0;
    });
    // Minimal delay - just enough for animation to complete
    await Future.delayed(const Duration(milliseconds: 300));
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() async {
    try {
      debugPrint('🔍 Checking onboarding status...');
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('onboarded_user') ?? false;
      debugPrint('📋 Onboarding completed: $hasCompletedOnboarding');

      final String? authToken =
          await UserAuthService().getToken(); // Get the saved token
      debugPrint('🔑 Auth token exists: ${authToken != null}');

      if (!mounted) {
        debugPrint('⚠️ Widget not mounted, skipping navigation');
        return;
      }

      if (authToken != null) {
        // Token exists - PERPETUAL LOGIN: Keep user logged in regardless of validation
        debugPrint('🔑 Token found - Implementing perpetual login');

        try {
          debugPrint('🌐 Attempting to fetch user data and payment keys...');
          final authService = UserAuthService();
          final paymentService = PaymentService();

          // Try to fetch fresh data with timeout
          final results = await Future.wait([
            authService.fetchUserData().timeout(const Duration(seconds: 5)),
            paymentService.getPaymentKeys().timeout(const Duration(seconds: 5)),
          ]).timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              debugPrint('⚠️ Timeout reached - will use cached/default data');
              throw TimeoutException('Overall request timeout');
            },
          );

          debugPrint('✅ User data and payment keys fetched successfully');
          final userData = results[0];
          final paymentKeys = results[1] as Map<String, String>;

          if (!mounted) {
            debugPrint(
                '⚠️ Widget not mounted after fetch, skipping navigation');
            return;
          }

          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.setUser(userData['data']);

          // Try to get public key from backend, fallback to .env if it fails
          String? publicKey = paymentKeys['publicKey'];

          if (publicKey == null || publicKey.isEmpty) {
            debugPrint(
                '⚠️ Public key from backend is null, using .env fallback');
            publicKey = dotenv.env['PAYSTACK_PUBLIC_KEY'];
          }

          if (publicKey != null && publicKey.isNotEmpty) {
            userProvider.setPaymentKeys(publicKey, '');
            debugPrint('✅ Payment public key loaded successfully');
          } else {
            debugPrint('⚠️ No payment key available - will use default');
          }

          // Send FCM token (non-blocking)
          debugPrint('📲 Sending pending FCM token (if any)...');
          try {
            final FirebaseMessagingService firebaseMessagingService =
                FirebaseMessagingService(navigatorKey);
            await firebaseMessagingService
                .sendPendingFCMToken(authToken)
                .timeout(const Duration(seconds: 3));
            debugPrint('✅ FCM token sent successfully');
          } catch (e) {
            debugPrint('⚠️ FCM token send failed (non-critical): $e');
          }
        } catch (e) {
          // ✅ PERPETUAL LOGIN: Don't logout on errors
          debugPrint('⚠️ Failed to fetch fresh data: $e');
          debugPrint('📱 Continuing with perpetual login (cached data)');
          // User stays logged in even if validation fails
        }

        // ✅ ALWAYS navigate to app if token exists (perpetual login)
        if (!mounted) {
          debugPrint('⚠️ Widget not mounted before navigation, aborting');
          return;
        }

        debugPrint(
            '🚀 Navigating to ${hasCompletedOnboarding ? "MainLayout" : "PermitNotificationScreen"}');
        if (hasCompletedOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PermitNotificationScreen()),
          );
        }
      } else {
        // No token found, user is not logged in
        debugPrint('🚫 No auth token found');
        if (hasCompletedOnboarding) {
          // User completed onboarding previously but is now logged out
          debugPrint(
              '🚀 Navigating to LoginScreen (onboarding completed, no token)');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          // New user, or user logged out and never completed onboarding
          debugPrint('🚀 Navigating to OnboardingScreen (new user)');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } catch (e, stackTrace) {
      // ✅ Ultimate fallback - if anything goes wrong, navigate to onboarding
      debugPrint('❌ CRITICAL ERROR in _checkOnboardingStatus: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;

      // Try to determine the best fallback screen
      try {
        final prefs = await SharedPreferences.getInstance();
        final hasCompletedOnboarding = prefs.getBool('onboarded_user') ?? false;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => hasCompletedOnboarding
                ? const LoginScreen()
                : const OnboardingScreen(),
          ),
        );
      } catch (fallbackError) {
        debugPrint('❌ Fallback navigation error: $fallbackError');
        // Last resort - go to onboarding
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kGrey100,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 200),
              child: Image.asset(
                'assets/images/cribs_arena_logo_dark.jpg',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
