import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/password_reset_service.dart';
import 'password_reset_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final PasswordResetService _passwordResetService = PasswordResetService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    SnackbarHelper.showInfo(context, 'Sending reset code...',
        position: FlashPosition.bottom);

    try {
      final response = await _passwordResetService.sendResetCode(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response['statusCode'] >= 200 && response['statusCode'] < 300) {
        SnackbarHelper.showSuccess(
          context,
          'Reset code sent! Check your email.',
          position: FlashPosition.bottom,
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Navigate to verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        final message =
            response['body']['message'] ?? 'Failed to send reset code';
        SnackbarHelper.showError(context, message,
            position: FlashPosition.bottom);
      }
    } catch (e) {
      debugPrint('Send code error: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'An error occurred. Please try again.',
          position: FlashPosition.bottom,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: const PrimaryAppBar(
        title: Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPaddingH24V16,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const AuthHeader(title: 'Reset Your Password'),
                Center(
                  child: Text(
                    'Enter your email address and we\'ll send you a verification code to reset your password.',
                    style: kAuthBodyTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                PrimaryButton(
                  text: _isLoading ? 'Sending Code...' : 'Send Reset Code',
                  onPressed: _isLoading ? null : _handleSendCode,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
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
