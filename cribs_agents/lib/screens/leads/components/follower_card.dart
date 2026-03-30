import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/follower.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;

class FollowerCard extends StatelessWidget {
  final Follower follower;
  final VoidCallback? onChatPressed;

  const FollowerCard({
    super.key,
    required this.follower,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = follower.user;
    final followedDate = follower.createdAt != null
        ? timeago.format(DateTime.parse(follower.createdAt!))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withValues(alpha: 0.3),
                        kPrimaryColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: kGrey200,
                    backgroundImage: _getImageProvider(user?.profilePictureUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Unknown User',
                        style: GoogleFonts.outfit(
                          color: kBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withValues(alpha: 0.1),
                                  kPrimaryColor.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 12,
                                  color: Colors.purple.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Saved You',
                                  style: GoogleFonts.roboto(
                                    color: Colors.purple.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (followedDate.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              followedDate,
                              style: GoogleFonts.roboto(
                                color: kGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildActionButton(
              'assets/icons/chat.svg',
              'Chat',
              onChatPressed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String iconPath,
    String label,
    VoidCallback? onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kLightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              height: 18,
              width: 18,
              colorFilter: const ColorFilter.mode(
                kPrimaryColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: kFontSize10,
                fontWeight: FontWeight.w500,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getResolvedImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final String baseUrl = kMainBaseUrl.endsWith('/')
        ? kMainBaseUrl.substring(0, kMainBaseUrl.length - 1)
        : kMainBaseUrl;

    String finalPath = path;

    if (!finalPath.startsWith('storage/') &&
        !finalPath.startsWith('/storage/')) {
      finalPath =
          'storage/${finalPath.startsWith('/') ? finalPath.substring(1) : finalPath}';
    }

    if (finalPath.startsWith('/')) {
      return '$baseUrl$finalPath';
    } else {
      return '$baseUrl/$finalPath';
    }
  }

  ImageProvider _getImageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('assets/images/default_profile.jpg');
    }

    return NetworkImage(_getResolvedImageUrl(path));
  }
}
