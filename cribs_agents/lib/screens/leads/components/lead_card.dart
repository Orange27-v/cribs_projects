import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/lead.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onChatPressed;

  const LeadCard({
    super.key,
    required this.lead,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = lead.user;
    final property = lead.property;

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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: kGrey200,
                    backgroundImage: _getImageProvider(user?.profilePictureUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Unknown User',
                        style: GoogleFonts.outfit(
                          color: kBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Interested in property',
                          style: GoogleFonts.roboto(
                            color: kPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (property != null) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // Property Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (property.mainImageUrl != null &&
                            property.mainImageUrl!.isNotEmpty)
                        ? Image.network(
                            _getResolvedImageUrl(property.mainImageUrl,
                                isProperty: true),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    width: 60,
                                    height: 60,
                                    color: kGrey100,
                                    child: const Icon(Icons.error,
                                        size: 20, color: kGrey)),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: kGrey100,
                            child:
                                const Icon(Icons.home, size: 20, color: kGrey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: kBlack,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: kGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  color: kGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₦${_formatPrice(property.price)}',
                          style: GoogleFonts.outfit(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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

  // Helper method to resolve image URLs
  String _getResolvedImageUrl(String? path, {bool isProperty = false}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Remove trailing slash from base URL
    final String baseUrl = kMainBaseUrl.endsWith('/')
        ? kMainBaseUrl.substring(0, kMainBaseUrl.length - 1)
        : kMainBaseUrl;

    String finalPath = path;

    // Handle property images specifically if they are just filenames
    if (isProperty) {
      if (!finalPath.contains('/') &&
          !finalPath.startsWith('property_images/')) {
        finalPath = 'property_images/$finalPath';
      }
    }

    // Ensure it starts with storage/ if not already present
    if (!finalPath.startsWith('storage/') &&
        !finalPath.startsWith('/storage/')) {
      finalPath =
          'storage/${finalPath.startsWith('/') ? finalPath.substring(1) : finalPath}';
    }

    // Ensure single slash between base URL and path
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

  // Helper method to format price in summarized format
  static String _formatPrice(String price) {
    try {
      // Remove any commas and parse to double
      final numericPrice = double.parse(price.replaceAll(',', ''));

      if (numericPrice >= 1000000000) {
        // Billions
        final formatted = (numericPrice / 1000000000);
        return formatted % 1 == 0
            ? '${formatted.toInt()}B'
            : '${formatted.toStringAsFixed(1)}B';
      } else if (numericPrice >= 1000000) {
        // Millions
        final formatted = (numericPrice / 1000000);
        return formatted % 1 == 0
            ? '${formatted.toInt()}M'
            : '${formatted.toStringAsFixed(1)}M';
      } else if (numericPrice >= 1000) {
        // Thousands
        final formatted = (numericPrice / 1000);
        return formatted % 1 == 0
            ? '${formatted.toInt()}K'
            : '${formatted.toStringAsFixed(1)}K';
      } else {
        // Less than 1000, show as is
        return numericPrice.toStringAsFixed(0);
      }
    } catch (e) {
      // If parsing fails, return original price
      return price;
    }
  }
}
