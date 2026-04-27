import 'package:cribs_agents/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import 'package:cribs_agents/services/auth_service.dart'; // Import AuthService

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Padding(padding: kPaddingH32, child: _WelcomeScreenContent()),
      ),
    );
  }
}

class _WelcomeScreenContent extends StatefulWidget {
  const _WelcomeScreenContent();

  @override
  State<_WelcomeScreenContent> createState() => _WelcomeScreenContentState();
}

class _WelcomeScreenContentState extends State<_WelcomeScreenContent> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _completeOnboarding(BuildContext context, {int initialIndex = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded_agent', true);

    try {
      final authService = AuthService();
      final userData = await authService.fetchUserData();

      final latitudeValue = userData['data']['latitude'];
      final longitudeValue = userData['data']['longitude'];

      final double userLatitude = latitudeValue is double
          ? latitudeValue
          : double.tryParse(latitudeValue?.toString() ?? '0') ?? 0.0;

      final double userLongitude = longitudeValue is double
          ? longitudeValue
          : double.tryParse(longitudeValue?.toString() ?? '0') ?? 0.0;

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainLayout(
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            initialIndex: initialIndex,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error fetching user data in WelcomeScreen: $e');
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainLayout(
            userLatitude: 0.0,
            userLongitude: 0.0,
            initialIndex: initialIndex,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleImageContainer(
          imagePath: 'assets/images/cribs_agents_logo_dark.png',
          size: 100,
        ),
        const SizedBox(height: 32),
        Text(
          'BEGIN YOUR \n SALES JOURNEY',
          style: kTitleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Onboarding complete — you can visit your dashboard or start with listing your first property',
          style: kSubtitleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        PrimaryButton(
          text: 'Get Started',
          onPressed: () => _completeOnboarding(context),
        ),
        const SizedBox(height: 16),
        OutlinedActionButton(
          text: 'List A Property',
          iconWidget: SvgPicture.asset(
            'assets/icons/house.svg',
            colorFilter: const ColorFilter.mode(kBlack, BlendMode.srcIn),
            height: 24,
          ),
          onPressed: () => _completeOnboarding(context, initialIndex: 2),
        ),
      ],
    );
  }
}
