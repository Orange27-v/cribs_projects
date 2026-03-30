import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../services/password_reset_service.dart';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final PasswordResetService _passwordResetService = PasswordResetService();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter and confirm your password')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _passwordResetService.resetPassword(
        email: widget.email,
        token: widget.token,
        newPassword: password,
      );

      if (!mounted) return;

      if (response['statusCode'] >= 200 && response['statusCode'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset successfully! Please login.')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['body']['message'] ?? 'Reset failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const AuthHeader(title: 'Set New Password'),
              const SizedBox(height: 16),
              const Text(
                'Your new password must be different from previously used passwords.',
                style: TextStyle(color: kGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomPasswordField(
                controller: _passwordController,
                labelText: 'New Password',
                hintText: 'Enter new password',
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              CustomPasswordField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Confirm new password',
                enabled: !_isLoading,
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                text: _isLoading ? 'Resetting...' : 'Reset Password',
                onPressed: _isLoading ? null : _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
