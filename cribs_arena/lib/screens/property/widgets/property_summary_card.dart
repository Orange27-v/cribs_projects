import 'package:cribs_arena/screens/property/property_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/constants.dart';
import 'package:heroicons/heroicons.dart';

class PropertySummaryCard extends StatelessWidget {
  final Property property;
  final Function(Property p1) onRemove;
  final bool showRemoveIcon;

  const PropertySummaryCard({
    super.key,
    required this.property,
    required this.onRemove,
    this.showRemoveIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        property.images.isNotEmpty ? property.images.first : '';
    final String fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '$kMainBaseUrl/storage/$imageUrl';

    return InkWell(
      borderRadius: kRadius8,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(property: property)),
        );
      },
      child: ClipRRect(
        borderRadius: kRadius8,
        child: Container(
          decoration: BoxDecoration(
            color: kGrey100Opacity05,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8.0,
                offset: const Offset(0, 4),
                spreadRadius: 0.0,
              ),
            ],
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
            final imageHeight = width * 0.58;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isEmpty
                          ? Image.asset(
                              'assets/images/property_skeleton.jpg',
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              fullImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/images/property_skeleton.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                      Positioned(
                        top: kSizedBoxH12,
                        left: kSizedBoxW12,
                        child: Container(
                          padding: kPaddingH10V5,
                          decoration: const BoxDecoration(
                            color: kBlackOpacity065,
                            borderRadius: kRadius8,
                          ),
                          child: Text(
                            property.type,
                            style: GoogleFonts.roboto(
                              color: kWhite,
                              fontSize: kFontSize10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (showRemoveIcon)
                        Positioned(
                          top: kSizedBoxH10,
                          right: kSizedBoxW10,
                          child: GestureDetector(
                            onTap: () => onRemove(property),
                            child: Container(
                              padding: kPaddingAll6,
                              decoration: const BoxDecoration(
                                color: kBlackOpacity045,
                                shape: BoxShape.circle,
                              ),
                              child: const HeroIcon(
                                HeroIcons.trash,
                                style: HeroIconStyle.outline,
                                color: kWhite,
                                size: kIconSize18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        property.title,
                        style: GoogleFonts.roboto(
                          fontSize: kFontSize12,
                          fontWeight: FontWeight.w500,
                          color: kBlack87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: kPrimaryColor, size: kIconSize14),
                          const SizedBox(width: kSizedBoxW6),
                          Expanded(
                            child: Text(
                              property.location,
                              style: GoogleFonts.roboto(
                                fontSize: kFontSize10,
                                color: kGrey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: kSizedBoxW10,
                        runSpacing: 2,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildStatItem(
                              Icons.king_bed_outlined, '${property.beds} Beds'),
                          _buildStatItem(Icons.bathtub_outlined,
                              '${property.baths} Baths'),
                          if (property.sqft > 0)
                            _buildStatItem(Icons.square_foot_outlined,
                                '${property.sqft} sqft'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: kIconSize10, color: kGrey),
        const SizedBox(width: kSizedBoxW6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: kFontSize10,
              fontWeight: FontWeight.w500,
              color: kBlack54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
