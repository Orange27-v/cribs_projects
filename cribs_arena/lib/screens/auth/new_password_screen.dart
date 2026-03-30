import 'package:flutter/material.dart';
import 'package:flash/flash.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/password_reset_service.dart';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final PasswordResetService _passwordResetService = PasswordResetService();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    SnackbarHelper.showInfo(context, 'Resetting password...',
        position: FlashPosition.bottom);

    try {
      final response = await _passwordResetService.resetPassword(
        email: widget.email,
        code: widget.code,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response['statusCode'] >= 200 && response['statusCode'] < 300) {
        SnackbarHelper.showSuccess(
          context,
          'Password reset successful! Please log in.',
          position: FlashPosition.bottom,
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // Navigate to login screen and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        final message =
            response['body']['message'] ?? 'Failed to reset password';
        SnackbarHelper.showError(context, message,
            position: FlashPosition.bottom);
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
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
        title: Text('New Password'),
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
                const AuthHeader(title: 'Create New Password'),
                Text(
                  'Your new password must be different from previously used passwords.',
                  style: kAuthBodyTextStyle,
                ),
                const SizedBox(height: 40),
                CustomPasswordField(
                  controller: _passwordController,
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }

                    // Check for uppercase letter
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain at least one uppercase letter';
                    }

                    // Check for lowercase letter
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Password must contain at least one lowercase letter';
                    }

                    // Check for number
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }

                    // Check for special character
                    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                      return 'Password must contain at least one special character';
                    }

                    // Check for repeating characters (no more than 2 consecutive same characters)
                    if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
                      return 'Password cannot have more than 2 consecutive same characters';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomPasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter new password',
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }

                    // Also validate strength on confirm field
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain at least one uppercase letter';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Password must contain at least one lowercase letter';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }
                    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                      return 'Password must contain at least one special character';
                    }
                    if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
                      return 'Password cannot have more than 2 consecutive same characters';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 30),
                PrimaryButton(
                  text: _isLoading ? 'Resetting Password...' : 'Reset Password',
                  onPressed: _isLoading ? null : _handleResetPassword,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
