import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../services/password_reset_service.dart';
import 'password_reset_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = TextEditingController();
  final PasswordResetService _passwordResetService = PasswordResetService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _passwordResetService.forgotPassword(email: email);

      if (!mounted) return;

      if (response['statusCode'] >= 200 && response['statusCode'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset code sent!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetVerificationScreen(email: email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['body']['message'] ?? 'Request failed')),
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
        title: Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPaddingH24V16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const AuthHeader(title: 'Reset Password'),
              const SizedBox(height: 16),
              Text(
                'Enter your email address and we will send you a code to reset your password.',
                style: kAuthBodyTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _controller,
                hintText: 'Enter your email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                text: _isLoading ? 'Sending...' : 'Send Code',
                onPressed: _isLoading ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
