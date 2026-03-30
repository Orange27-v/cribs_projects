import 'package:cribs_agents/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import 'package:cribs_agents/screens/properties/properties_screen.dart';
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
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboarded_agent', true);

            // Fetch user data to get latitude and longitude for HomeScreen
            try {
              final authService = AuthService();
              final userData = await authService.fetchUserData();

              // Safely parse latitude and longitude from API response
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
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error fetching user data in WelcomeScreen: $e');
              // Fallback to HomeScreen without coordinates or show an error
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainLayout(
                    userLatitude: 0.0,
                    userLongitude: 0.0,
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        OutlinedActionButton(
          text: 'List A Property',
          iconWidget: SvgPicture.asset(
            'assets/icons/house.svg',
            colorFilter: const ColorFilter.mode(kBlack, BlendMode.srcIn),
            height: 24,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PropertiesScreen()),
            );
          },
        ),
      ],
    );
  }
}
