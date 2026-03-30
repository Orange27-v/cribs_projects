import 'dart:async';
import 'package:cribs_agents/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding_screen.dart';
import '../../constants.dart';
import 'package:cribs_agents/services/auth_service.dart'; // Import AuthService
import 'package:cribs_agents/screens/auth/login_screen.dart'; // Import LoginScreen
import 'package:cribs_agents/screens/onboarding/permit_notification_screen.dart'; // Import PermitNotificationScreen
import 'package:cribs_agents/services/firebase_messaging_service.dart'; // Import FirebaseMessagingService
import 'package:cribs_agents/main.dart'
    show navigatorKey; // Import navigatorKey from main.dart

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
      final hasCompletedOnboarding = prefs.getBool('onboarded_agent') ?? false;
      debugPrint('📋 Onboarding completed: $hasCompletedOnboarding');

      final String? authToken =
          await AuthService().getToken(); // Get the saved token
      debugPrint('🔑 Auth token exists: ${authToken != null}');

      if (!mounted) {
        debugPrint('⚠️ Widget not mounted, skipping navigation');
        return;
      }

      if (authToken != null) {
        // Token exists - PERPETUAL LOGIN: Keep user logged in regardless of validation
        debugPrint('🔑 Token found - Implementing perpetual login');

        double userLatitude = 0.0;
        double userLongitude = 0.0;

        try {
          debugPrint('🌐 Attempting to fetch user data...');
          final authService = AuthService();

          // Try to fetch fresh data with timeout
          final userData = await authService
              .fetchUserData()
              .timeout(const Duration(seconds: 5));

          debugPrint('✅ User data fetched successfully');

          if (!mounted) {
            debugPrint(
                '⚠️ Widget not mounted after fetch, skipping navigation');
            return;
          }

          // Safely parse latitude and longitude from API response
          final latitudeValue = userData['data']['latitude'];
          final longitudeValue = userData['data']['longitude'];

          userLatitude = latitudeValue is double
              ? latitudeValue
              : double.tryParse(latitudeValue?.toString() ?? '0') ?? 0.0;

          userLongitude = longitudeValue is double
              ? longitudeValue
              : double.tryParse(longitudeValue?.toString() ?? '0') ?? 0.0;

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
          // Coordinates will remain 0.0 if fetch failed
        }

        // ✅ ALWAYS navigate to app if token exists (perpetual login)
        if (!mounted) {
          debugPrint('⚠️ Widget not mounted before navigation, aborting');
          return;
        }

        debugPrint(
            '🚀 Navigating to ${hasCompletedOnboarding ? "HomeScreen" : "PermitNotificationScreen"}');
        if (hasCompletedOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainLayout(
                userLatitude: userLatitude,
                userLongitude: userLongitude,
              ),
            ),
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
        if (!mounted) return;

        final hasCompletedOnboarding =
            prefs.getBool('onboarded_agent') ?? false;

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
                'assets/images/cribs_agents_logo_dark.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
