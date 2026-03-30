import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/models/listed_property.dart';
import 'package:cribs_arena/constants.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PropertyListItem extends StatefulWidget {
  final ListedProperty property;
  final VoidCallback? onBookmarkTap;

  const PropertyListItem({
    super.key,
    required this.property,
    this.onBookmarkTap,
  });

  @override
  State<PropertyListItem> createState() => _PropertyListItemState();
}

class _PropertyListItemState extends State<PropertyListItem> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storageBase = Uri.parse('$kMainBaseUrl/storage/');
    final p = widget.property;

    return Container(
      decoration: BoxDecoration(
        color: kGrey100Opacity06, // full widget background
        borderRadius: kRadius8,
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8.0,
            offset: kOffset02,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE SECTION
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: kRadius8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image Slider
                    if (p.images.isNotEmpty)
                      PageView.builder(
                        controller: _pageController,
                        itemCount: p.images.length,
                        itemBuilder: (context, index) {
                          final imageUrl = storageBase.resolve(p.images[index]);
                          return Image.network(
                            imageUrl.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/property_skeleton.jpg',
                                fit: BoxFit.cover),
                          );
                        },
                      )
                    else
                      Image.asset(
                        'assets/images/property_skeleton.jpg',
                        fit: BoxFit.cover,
                      ),

                    // Type Badge
                    Positioned(
                      top: kSizedBoxH12,
                      left: kSizedBoxW12,
                      child: Container(
                        padding: kPaddingH12V6,
                        decoration: const BoxDecoration(
                          color: kGrey100Opacity05,
                          borderRadius: kRadius8,
                        ),
                        child: Text(
                          p.type,
                          style: GoogleFonts.roboto(
                            color: kWhite,
                            fontSize: kFontSize10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Page Indicator
                    if (p.images.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: p.images.length,
                            effect: const WormEffect(
                              dotHeight: 6,
                              dotWidth: 6,
                              activeDotColor: kWhite,
                              dotColor: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // CONTENT SECTION
            Expanded(
              flex: 3,
              child: Padding(
                padding: kPaddingAll12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row (type + bookmark)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: kPaddingH10V4,
                          decoration: const BoxDecoration(
                            color: kPrimaryColorOpacity01,
                            borderRadius: kRadius8,
                          ),
                          child: Text(
                            p.type,
                            style: GoogleFonts.roboto(
                              fontSize: kFontSize8,
                              fontWeight: FontWeight.w400,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onBookmarkTap,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              p.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border_outlined,
                              color: p.isBookmarked ? kPrimaryColor : kGrey400,
                              size: kIconSize22,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Middle (title + location)
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.title,
                            style: GoogleFonts.roboto(
                              fontSize: kFontSize12,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: kSizedBoxH4),
                          Text(
                            p.location,
                            style: GoogleFonts.roboto(
                              fontSize: kFontSize12,
                              fontWeight: FontWeight.w400,
                              color: kBlack54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Bottom (stats + price)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (p.beds > 0)
                              _buildStat(Icons.king_bed_outlined, '${p.beds}'),
                            if (p.beds > 0 && p.baths > 0)
                              const SizedBox(width: kSizedBoxW12),
                            if (p.baths > 0)
                              _buildStat(Icons.bathtub_outlined, '${p.baths}'),
                          ],
                        ),
                        if (p.price != null)
                          Text(
                            '₦${_formatPrice(p.price ?? 0)}',
                            style: GoogleFonts.roboto(
                              fontSize: kFontSize16,
                              fontWeight: FontWeight.w700,
                              color: kBlack87,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: kIconSize16, color: kGrey400),
          const SizedBox(width: kSizedBoxW4),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: kFontSize12,
              fontWeight: FontWeight.w500,
              color: kBlack87,
            ),
          ),
        ],
      );

  String _formatPrice(double price) {
    if (price >= 1e9) return '${(price / 1e9).toStringAsFixed(1)}B';
    if (price >= 1e6) return '${(price / 1e6).toStringAsFixed(1)}M';
    if (price >= 1e3) return '${(price / 1e3).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
