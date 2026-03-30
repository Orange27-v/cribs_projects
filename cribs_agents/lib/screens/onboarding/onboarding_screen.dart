import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../models/onboarding_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
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
      backgroundColor: kWhite,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen PageView with custom onboarding pages
            _PageView(
              pageController: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),

            // Top bar overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(navigateToLogin: _navigateToLogin),
            ),

            // Bottom content overlay (indicators and button)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PageIndicator(pageController: _pageController),
                    const SizedBox(height: 24),
                    _NextButton(
                      currentPage: _currentPage,
                      pageController: _pageController,
                      navigateToSignup: _navigateToSignup,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Function(BuildContext) navigateToLogin;
  const _TopBar({required this.navigateToLogin});

  @override
  Widget build(BuildContext context) {
    return AuthTopBar(
      buttonText: "Sign In",
      onButtonPressed: () => navigateToLogin(context),
      horizontalPadding: 20.0,
    );
  }
}

class _PageView extends StatelessWidget {
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _PageView({
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: PageView.builder(
        controller: pageController,
        itemCount: contents.length,
        onPageChanged: onPageChanged,
        itemBuilder: (_, i) {
          return _OnboardingPage(content: contents[i]);
        },
      ),
    );
  }
}

// Custom onboarding page widget with gradient background and modern design
// Custom onboarding page widget with gradient background and modern design
class _OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const _OnboardingPage({required this.content});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image section - First (Background)
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.only(top: 40),
            child: Image.asset(
              content.image,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: kGrey500,
                  ),
                );
              },
            ),
          ),
        ),

        // Text content section - Second (Foreground, visible)
        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                content.title,
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: kOnboardingDescriptionStyle.copyWith(
                      fontSize: 16,
                      height: 1.5,
                      color: kBlack87.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final PageController pageController;
  const _PageIndicator({required this.pageController});

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: pageController,
      count: contents.length,
      effect: const ExpandingDotsEffect(
        activeDotColor: kPrimaryColor,
        dotColor: kGrey400,
        dotHeight: 10,
        dotWidth: 10,
        expansionFactor: 3,
        spacing: 8,
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final int currentPage;
  final PageController pageController;
  final Function(BuildContext) navigateToSignup;

  const _NextButton({
    required this.currentPage,
    required this.pageController,
    required this.navigateToSignup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: PrimaryButton(
        text: currentPage == contents.length - 1 ? 'Get Started' : 'Next',
        onPressed: () {
          if (currentPage == contents.length - 1) {
            navigateToSignup(context);
          } else {
            pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
    );
  }
}
