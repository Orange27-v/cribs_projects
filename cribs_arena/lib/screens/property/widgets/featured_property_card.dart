import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/constants.dart';
import '../property_details_screen.dart';

class FeaturedPropertyCard extends StatelessWidget {
  final Property property;

  const FeaturedPropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    // Get the image URL and convert to full URL if needed
    final String imageUrl =
        property.images.isNotEmpty ? property.images.first : '';
    final String fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '$kMainBaseUrl/storage/$imageUrl';

    return GestureDetector(
      onTap: () => _navigateToPropertyScreen(context),
      child: Container(
        width: 320,
        margin: kPaddingOnlyRight16,
        decoration: BoxDecoration(
          borderRadius: kRadius8,
          image: DecorationImage(
            image: imageUrl.isNotEmpty
                ? NetworkImage(fullImageUrl) as ImageProvider
                : const AssetImage('assets/images/property_skeleton.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: _buildOverlay(),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: kRadius8,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kBlack.withValues(alpha: 0.0),
            kBlackOpacity06,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildCardContent(),
        ],
      ),
    );
  }

  Widget _buildCardContent() {
    return Container(
      padding: kPaddingAll16,
      decoration: const BoxDecoration(
        color: kBlackOpacity03,
        borderRadius: kRadius16Bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPropertyInfo(),
          _buildViewButton(),
        ],
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.title, // Changed from property.name to property.title
            style: GoogleFonts.roboto(
              color: kWhite,
              fontSize: kFontSize18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kSizedBoxH4),
          Text(
            property.location,
            style: GoogleFonts.roboto(
              color: kWhiteOpacity08,
              fontSize: kFontSize14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton() {
    return Builder(builder: (context) {
      return ElevatedButton.icon(
        onPressed: () => _navigateToPropertyScreen(context),
        icon: const Icon(Icons.arrow_forward_ios, size: kIconSize16),
        label: const Text('View'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
          shape: const RoundedRectangleBorder(borderRadius: kRadius20),
          padding: kPaddingH20V12,
        ),
      );
    });
  }

  void _navigateToPropertyScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsScreen(
            property: property, isOwner: true), // Pass property object
      ),
    );
  }
}
