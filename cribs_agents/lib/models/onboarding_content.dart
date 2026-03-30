import '../widgets/onboarding_title.dart';

class OnboardingContent {
  final String image;
  final OnboardingTitle title;
  final String description;
  final double? imageHeight;
  final double? imageWidth;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
    this.imageHeight,
    this.imageWidth,
  });
}
