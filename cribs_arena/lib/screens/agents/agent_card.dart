import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/screens/agents/agent_profile_bottom_sheet.dart';

class AgentCard extends StatelessWidget {
  final Agent agent;

  const AgentCard({super.key, required this.agent});

  /// Builds star rating based on review count tiers
  /// 20+ reviews = 1 star, 100+ = 2 stars, 200+ = 3 stars
  Widget _buildReviewStars(int totalReviews) {
    int starCount = 0;
    if (totalReviews > 20) starCount = 1;
    if (totalReviews >= 100) starCount = 2;
    if (totalReviews >= 200) starCount = 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Icon(
          index < starCount ? Icons.star : Icons.star_border,
          color: kAmber,
          size: kIconSize18,
        ),
      ),
    );
  }

  /// Builds the online/offline status indicator
  Widget _buildStatusIndicator(bool isOnline) {
    return Positioned(
      top: kSizedBoxH0,
      right: kSizedBoxW2,
      child: Container(
        width: kSizedBoxW12,
        height: kSizedBoxH12,
        decoration: BoxDecoration(
          color: isOnline ? kGreen : kGrey,
          shape: BoxShape.circle,
          border: Border.all(color: kWhite, width: kStrokeWidth2),
        ),
      ),
    );
  }

  /// Builds the chat action button
  Widget _buildChatButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AgentProfileBottomSheet(agent: agent),
      ),
      child: Container(
        width: kSizedBoxH40,
        height: kSizedBoxH40,
        decoration: const BoxDecoration(
          color: kWhite,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: HeroIcon(
            HeroIcons.chatBubbleLeft,
            color: kPrimaryColorDark,
            size: kIconSize22,
          ),
        ),
      ),
    );
  }

  /// Builds the proper image provider for agent profile pictures
  ImageProvider _getAgentImageProvider() {
    final String profilePicturePath = agent.profileImage;

    if (profilePicturePath.isEmpty) {
      return const AssetImage('assets/images/default_profile.jpg');
    }

    if (profilePicturePath.startsWith('http')) {
      return NetworkImage(profilePicturePath);
    }

    // Clean the path
    String agentImagePath = profilePicturePath;

    // Remove leading slash if present
    if (agentImagePath.startsWith('/')) {
      agentImagePath = agentImagePath.substring(1);
    }

    // If it's already a full storage path (e.g., "storage/agent_pictures/1.jpg")
    if (agentImagePath.startsWith('storage/')) {
      final String fullImageUrl = '$kMainBaseUrl$agentImagePath';
      return NetworkImage(fullImageUrl);
    }

    // If it's a relative path like "agent_pictures/1.jpg" or "profile_pictures/xxx.jpg"
    if (agentImagePath.contains('agent_pictures/') ||
        agentImagePath.contains('profile_pictures/')) {
      final String fullImageUrl = '${kMainBaseUrl}storage/$agentImagePath';
      return NetworkImage(fullImageUrl);
    }

    // If it's just a filename, try agent_pictures first
    if (!agentImagePath.contains('/')) {
      final String fullImageUrl =
          '${kMainBaseUrl}storage/agent_pictures/$agentImagePath';
      return NetworkImage(fullImageUrl);
    }

    // Default fallback
    final String fullImageUrl = '${kMainBaseUrl}storage/$agentImagePath';
    return NetworkImage(fullImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        agent.fullName.isNotEmpty ? agent.fullName : 'Unknown Agent';
    final reviews = agent.totalReviews ?? 0;
    final isOnline = agent.loginStatus == 1;

    return Container(
      padding: kPaddingH8V12,
      decoration: BoxDecoration(
        color: kLightCyan,
        borderRadius: kRadius8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Picture with Status Indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: kRadiusDouble30 * 2,
                height: kRadiusDouble30 * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGrey200,
                ),
                clipBehavior: Clip.hardEdge,
                child: Image(
                  image: _getAgentImageProvider(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/default_profile.jpg',
                      fit: BoxFit.cover,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2.0,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      ),
                    );
                  },
                ),
              ),
              _buildStatusIndicator(isOnline),
            ],
          ),
          const SizedBox(height: kSizedBoxH8),

          // Agent Name
          Flexible(
            child: Text(
              fullName,
              style: GoogleFonts.roboto(
                fontSize: kFontSize11,
                fontWeight: FontWeight.w500,
                color: kPrimaryColorDark,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: kSizedBoxH1),

          // Licensed Agent Label
          Text(
            kLicensedAgentText,
            style: GoogleFonts.roboto(
              fontSize: kFontSize11,
              color: kDarkTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSizedBoxH6),

          // Reviews Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildReviewStars(reviews),
              const SizedBox(width: kSizedBoxW4),
              Flexible(
                child: Text(
                  '$reviews reviews',
                  style: GoogleFonts.roboto(
                    fontSize: kFontSize11,
                    color: kPrimaryColorDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSizedBoxH8),

          // Chat Button
          _buildChatButton(context),
        ],
      ),
    );
  }
}
