import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

class OnboardingTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const OnboardingTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: kBlack,
          height: 0.9,
          letterSpacing: -0.5,
        ),
        children: <TextSpan>[
          TextSpan(text: '$title\n'),
          TextSpan(
            text: subtitle,
            style: GoogleFonts.roboto(
              color: kPrimaryColor,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
