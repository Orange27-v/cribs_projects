import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../services/password_reset_service.dart';
import 'dart:async';
import 'new_password_screen.dart';

class PasswordResetVerificationScreen extends StatefulWidget {
  final String email;

  const PasswordResetVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetVerificationScreen> createState() =>
      _PasswordResetVerificationScreenState();
}

class _PasswordResetVerificationScreenState
    extends State<PasswordResetVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final PasswordResetService _passwordResetService = PasswordResetService();

  bool _isLoading = false;
  bool _isResending = false;
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleVerification() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit code')),
      );
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Verifying code...')));

    try {
      final response = await _passwordResetService.verifyResetToken(
        email: widget.email,
        token: code,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response['statusCode'] >= 200 && response['statusCode'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code verified successfully!')),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Navigate to new password screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordScreen(
              email: widget.email,
              token: code,
            ),
          ),
        );
      } else {
        final message = response['body']['message'] ?? 'Invalid code';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
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

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _handleResendCode() async {
    if (_isResending || !_canResend) return;

    setState(() {
      _isResending = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Resending code...')));

    try {
      final response = await _passwordResetService.forgotPassword(
        email: widget.email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response['statusCode'] >= 200 && response['statusCode'] < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Verification code resent successfully!')),
        );

        // Clear existing code
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();

        // Restart timer
        _startResendTimer();
      } else {
        final message = response['body']['message'] ?? 'Failed to resend code';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      debugPrint('Resend error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: PrimaryAppBar(
        title: const Text('Verify Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPaddingH24V16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const AuthHeader(title: 'Verify Reset Code'),
              const SizedBox(height: 16),
              Text(
                'We sent a 4-digit code to',
                style: kAuthBodyTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60.0,
                    height: 60.0,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_isLoading,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: kGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: kPrimaryColor,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }

                        // Auto-verify when all 4 digits are entered
                        if (index == 3 && value.isNotEmpty) {
                          _handleVerification();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                text: _isLoading ? 'Verifying...' : 'Verify Code',
                onPressed: _isLoading ? null : _handleVerification,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(color: kGrey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: (_isResending || !_canResend)
                        ? null
                        : _handleResendCode,
                    child: Text(
                      _isResending
                          ? 'Resending...'
                          : _canResend
                              ? 'Resend'
                              : 'Resend in $_resendCountdown s',
                      style: TextStyle(
                        color: (_isResending || !_canResend)
                            ? kGrey
                            : const Color(0xFF0066CC),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
