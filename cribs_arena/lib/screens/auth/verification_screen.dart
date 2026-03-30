import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../widgets/widgets.dart';
import '../../constants.dart';

class SmsVerificationScreen extends StatefulWidget {
  const SmsVerificationScreen({super.key});

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _seconds = 15;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        if (mounted) {
          setState(() {
            _seconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _onContinue() async {
    if (!_isOtpFilled) return;
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2)); // Simulate verification
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    // Show success SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification successful!'),
        duration: Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onResend() {
    setState(() {
      _seconds = 30;
    });
    _startTimer();
  }

  bool get _isOtpFilled => _controllers.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 40),
                const AuthHeader(title: 'VERIFY YOUR NUMBER'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'We have sent a 4-digit OTP to your registered phone number.\nEnter the code below to continue.',
                    textAlign: TextAlign.center,
                    style: kAuthBodyTextStyle,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      4,
                      (i) => OtpTextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 3) {
                                _focusNodes[i + 1].requestFocus();
                              } else if (val.isEmpty && i > 0) {
                                _focusNodes[i - 1].requestFocus();
                              }
                              setState(() {});
                            },
                          )),
                ),
                const SizedBox(height: 18),
                _seconds > 0
                    ? Text('Resend code in ${_seconds}s',
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black54))
                    : TextButton(
                        onPressed: _onResend,
                        child: const Text('Resend code',
                            style: kOtpResendTextStyle),
                      ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: kOtpResendTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: PrimaryButton(
                    text: 'Continue',
                    onPressed: _isOtpFilled && !_isLoading ? _onContinue : null,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: CustomLoadingIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
