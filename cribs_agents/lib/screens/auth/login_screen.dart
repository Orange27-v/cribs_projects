import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cribs_agents/services/firebase_messaging_service.dart';
import 'package:cribs_agents/main.dart' show navigatorKey;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'email_verification_screen.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import 'package:cribs_agents/services/auth_service.dart';
import 'package:cribs_agents/screens/onboarding/permit_notification_screen.dart';

import 'package:cribs_agents/screens/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService authService = AuthService();

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Please wait...')));

    try {
      final email = _emailPhoneController.text.trim();
      final password = _passwordController.text;

      // Firebase sign-in removed
      // Get FCM Token
      String? fcmToken;
      try {
        fcmToken =
            await FirebaseMessagingService(navigatorKey).getStoredFCMToken() ??
                await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'unknown';

      // Proceed with backend login.
      var loginResponse = await authService.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
        platform: platform,
      );
      if (loginResponse.statusCode >= 200 && loginResponse.statusCode < 300) {
        // Token is now saved by AuthService().login()
        // Send FCM token to server after successful login
        try {
          await FirebaseMessagingService(navigatorKey).sendTokenToServer();
          debugPrint('FCM token sent after login');
        } catch (e) {
          debugPrint('Error sending FCM token after login: $e');
        }

        // Check if agent has completed onboarding
        final prefs = await SharedPreferences.getInstance();
        final hasCompletedOnboarding =
            prefs.getBool('onboarded_agent') ?? false;

        if (mounted) {
          if (hasCompletedOnboarding) {
            // Agent has completed onboarding, fetch user data and navigate to HomeScreen
            final userData = await authService.fetchUserData();

            if (!mounted) return;
            debugPrint('User data fetched: $userData'); // For debugging

            // Safely parse latitude and longitude from API response
            final latitudeValue = userData['data']['latitude'];
            final longitudeValue = userData['data']['longitude'];

            final double userLatitude = latitudeValue is double
                ? latitudeValue
                : double.tryParse(latitudeValue?.toString() ?? '0') ?? 0.0;

            final double userLongitude = longitudeValue is double
                ? longitudeValue
                : double.tryParse(longitudeValue?.toString() ?? '0') ?? 0.0;

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
            // Agent hasn't completed onboarding, navigate to PermitNotificationScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PermitNotificationScreen(),
              ),
            );
          }
        }
      } else if (loginResponse.statusCode == 403) {
        final responseBody = jsonDecode(loginResponse.body);
        if (responseBody['requires_verification'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email verification required.')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(email: email),
              ),
            );
          }
          return;
        }
        throw Exception(responseBody['message'] ?? 'Login failed');
      } else {
        final responseBody = jsonDecode(loginResponse.body);
        throw Exception(responseBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPaddingH24V16,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AuthTopBar(
                  buttonText: kSignUpText,
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const AuthHeader(title: 'Welcome Back'),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailPhoneController,
                  hintText: kLoginEmailPhoneHint,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or phone number';
                    }
                    return null;
                  },
                  inputFormatters: const [],
                ),
                const SizedBox(height: 16),
                CustomPasswordField(
                  controller: _passwordController,
                  labelText: kLoginPasswordHint,
                  hintText: kLoginPasswordHint,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(text: kSignInText, onPressed: _handleSignIn),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: kSignUpText,
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                      ),
                    ],
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
