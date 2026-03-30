import 'package:cribs_arena/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Padding(
          padding: kPaddingH24V16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const CircleImageContainer(
                imagePath: 'assets/images/app_logo.png',
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                'WELCOME TO CRIBS ARENA!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kBlack,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your journey to finding the perfect property starts here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kBlack54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),
              PrimaryButton(
                text: 'Get Started',
                onPressed: () async {
                  // Mark onboarding as complete
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarded_user', true);

                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainLayout(),
                      ),
                    );
                  }
                },
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
