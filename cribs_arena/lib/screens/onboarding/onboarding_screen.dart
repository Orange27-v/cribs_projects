import 'package:flutter/material.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart'; // Import the LoginScreen
import '../../constants.dart';
import '../../widgets/widgets.dart'; // Import the updated widgets file

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 700), // Duration of the zoom animation
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      // Zoom in from 80% to 100%
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic, // A nice, smooth zoom curve
      ),
    );

    _animationController.forward(); // Start the animation when the screen loads
  }

  @override
  void dispose() {
    _animationController
        .dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignupScreen(),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: ScaleTransition(
          // Wrap the entire body content with ScaleTransition
          scale: _scaleAnimation,
          child: _OnboardingScreenContent(
            navigateToLogin: _navigateToLogin,
            navigateToSignup: _navigateToSignup,
          ),
        ),
      ),
    );
  }
}

class _OnboardingScreenContent extends StatelessWidget {
  final Function(BuildContext) navigateToLogin;
  final Function(BuildContext) navigateToSignup;
  const _OnboardingScreenContent(
      {required this.navigateToLogin, required this.navigateToSignup});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with location icon and Sign In
        AuthTopBar(
          // Reusing the AuthTopBar widget
          buttonText: "Sign In",
          onButtonPressed: () => navigateToLogin(context),
          horizontalPadding: 20.0,
        ),

        // Image (map & faces inside magnifying glass)
        const SizedBox(height: 10),
        Expanded(
          child: SizedBox.expand(
            child: Image.asset(
              'assets/images/onboarding_map.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topRight,
            ),
          ),
        ),
        // Texts
        const Padding(
          padding: EdgeInsets.only(
            top: 10,
          ),
          child: Column(
            children: [
              Text(
                "FIND AGENTS & LANDLORDS \n NEAR YOU INSTANTLY",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kBlack,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "See real estate agents & landlords and their listings on a live map centered around your location.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: kBlack87,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 35),

        // Refactored Get Started Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: PrimaryButton(
            text: 'Get Started',
            onPressed: () => navigateToSignup(context),
          ),
        ),

        // Removed the "I am an Agent" and "I am a Landlord" buttons section
        // as per new requirements for separate agent/client apps.

        const SizedBox(height: 60), // Final spacing at the bottom
      ],
    );
  }
}
