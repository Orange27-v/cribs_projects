import 'package:flutter/material.dart';
import '../models/onboarding_content.dart';
import '../constants.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const OnboardingPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image - fills entire screen
        Positioned.fill(
          child: Image.asset(
            content.image,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: kGrey100,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported,
                    size: 48, color: kGrey500),
              );
            },
          ),
        ),
        // Text content - positioned at the bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 40, right: 40, bottom: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                content.title,
                const SizedBox(height: 8),
                Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: kOnboardingDescriptionStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
