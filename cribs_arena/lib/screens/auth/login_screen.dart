import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cribs_arena/main.dart' show navigatorKey;
import 'package:cribs_arena/services/firebase_messaging_service.dart';
import 'package:cribs_arena/screens/splash/splash_screen.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import '../../utils/snackbar_helper.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import 'package:cribs_arena/services/user_auth_service.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserAuthService authService = UserAuthService();
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
    });

    if (mounted) {
      SnackbarHelper.showInfo(context, 'Please wait...',
          position: FlashPosition.bottom);
    }

    try {
      final email = _emailPhoneController.text.trim();
      final password = _passwordController.text;

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

      // Backend login
      var loginResponse = await authService.loginService.login(
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

        // Fetch user data after successful login
        final userData = await authService.fetchUserData();

        try {
          debugPrint('User data fetched: $userData'); // For debugging
          debugPrint('User data type: ${userData.runtimeType}');
          debugPrint('User data keys: ${userData.keys}');
          debugPrint('About to access data field...');
          final dataField = userData['data'];
          debugPrint('Data field: $dataField');
          debugPrint('Data field type: ${dataField.runtimeType}');
        } catch (e, stack) {
          debugPrint('ERROR in debug prints: $e');
          debugPrint('Stack: $stack');
          rethrow;
        }

        if (mounted) {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);

          // Null safety check
          if (userData['data'] != null) {
            debugPrint('Setting user data in provider...');
            userProvider.setUser(userData['data']);
            debugPrint('User data set successfully');
          } else {
            debugPrint('ERROR: userData[\'data\'] is null!');
            throw Exception('User data is null');
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
          );
        }
      } else if (loginResponse.statusCode == 403) {
        // Email not verified
        final responseBody = jsonDecode(loginResponse.body);

        if (responseBody['requires_verification'] == true) {
          if (mounted) {
            // Show informative error message
            SnackbarHelper.showError(
              context,
              'Please verify your email address to continue.',
              position: FlashPosition.bottom,
            );

            await Future.delayed(const Duration(seconds: 2));

            if (!mounted) return;

            // Navigate to email verification screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: responseBody['email'] ??
                      _emailPhoneController.text.trim(),
                ),
              ),
            );
          }
        } else {
          throw Exception(responseBody['error'] ?? 'Access denied');
        }
      } else {
        final responseBody = jsonDecode(loginResponse.body);
        throw Exception(responseBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        SnackbarHelper.showError(context, errorMessage,
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
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
                          builder: (context) => const SignupScreen()),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const AuthHeader(title: 'Welcome Back'),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailPhoneController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or phone number';
                    }
                    return null;
                  },
                  inputFormatters: [],
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
                const SizedBox(height: 8),
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
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: _isLoggingIn ? 'Checking....' : kSignInText,
                  onPressed: _isLoggingIn ? null : _handleSignIn,
                ),
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
                                  builder: (context) => const SignupScreen()),
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
