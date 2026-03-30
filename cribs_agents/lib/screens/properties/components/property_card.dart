import 'package:cribs_agents/models/property.dart';
import 'package:cribs_agents/screens/properties/edit_property_screen.dart';
import 'package:cribs_agents/screens/properties/view_property_screen.dart';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/services/property_service.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final bool isViewing;
  final VoidCallback? onDelete;
  const PropertyCard({
    super.key,
    required this.property,
    this.isViewing = false,
    this.onDelete,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<String> get propertyImages => widget.property.images ?? [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onImageTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenImageViewer(
          imageUrls: propertyImages.map((e) => _getImageUrl(e)).toList(),
          initialIndex: _currentPage,
        ),
      ),
    );
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '$kMainBaseUrl/storage/property_images/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _onImageTap,
                child: ClipRRect(
                  borderRadius: kRadius12,
                  child: SizedBox(
                    height: 230,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: propertyImages.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          _getImageUrl(propertyImages[index]),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: kLightBlue,
                    borderRadius: kRadius8,
                  ),
                  child: Text(
                    widget.property.listingType,
                    style: GoogleFonts.roboto(
                      color: kPrimaryColor,
                      fontSize: kFontSize12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    _showDeleteConfirmation(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: kWhite,
                      borderRadius: kRadius12,
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/trash-pattern.svg',
                      colorFilter:
                          const ColorFilter.mode(kBlack, BlendMode.srcIn),
                      height: 20,
                      width: 20,
                    ),
                  ),
                ),
              ),
              if (propertyImages.length > 1)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Row(
                    children: List.generate(
                      propertyImages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? kWhite
                              : kWhite.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.property.title,
                            style: GoogleFonts.roboto(
                              fontSize: kFontSize14,
                              fontWeight: FontWeight.w500,
                              color: kBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₦${NumberFormat('#,##0.00').format(widget.property.price)}',
                            style: GoogleFonts.roboto(
                              fontSize: kFontSize16,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: kRadius8,
                      ),
                      child: Text(
                        widget.property.type,
                        style: GoogleFonts.roboto(
                          color: kPrimaryColor,
                          fontSize: kFontSize12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPropertyInfo('${widget.property.beds}', 'Beds'),
                    _buildDot(),
                    _buildPropertyInfo('${widget.property.baths}', 'Baths'),
                    if (widget.property.sqft != null) ...[
                      _buildDot(),
                      _buildPropertyInfo(widget.property.sqft!, 'Sq ft'),
                    ],
                    _buildDot(),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isViewing) {
                            _showFullAddress(
                              context,
                              '123 Johnson Estate, ${widget.property.location}',
                            );
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: kBlack,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.property.location,
                                style: GoogleFonts.roboto(
                                  fontSize: kFontSize12,
                                  color: kBlack,
                                ),
                                maxLines: widget.isViewing ? null : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.property.description ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: kFontSize14,
                    fontWeight: FontWeight.w500,
                    color: kBlack87,
                    height: 1.4,
                  ),
                  maxLines: widget.isViewing ? null : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                const Divider(color: kBlack, thickness: 0.5, height: 15),
                Row(
                  children: [
                    _buildStatItem(Icons.trending_up,
                        '${widget.property.viewCount} views', Colors.green),
                    const SizedBox(width: 20),
                    _buildStatItem(
                      Icons.verified_outlined,
                      '${widget.property.inspectionBookingCount} inspections',
                      kPrimaryColor,
                    ),
                    const SizedBox(width: 20),
                    _buildStatItem(
                      Icons.calendar_month,
                      '${widget.property.leadsCount} leads',
                      Colors.purple,
                    ),
                  ],
                ),
                const Divider(
                  color: kBlack,
                  thickness: 0.5,
                  indent: 1,
                  endIndent: 0,
                  height: 15,
                ),
                if (!widget.isViewing)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              iconPath: 'assets/icons/eye.svg',
                              label: 'View',
                              isPrimary: false,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewPropertyScreen(
                                      property: widget.property,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              iconPath: 'assets/icons/edit.svg',
                              label: 'Edit',
                              isPrimary: false,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPropertyScreen(
                                      property: widget.property,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyInfo(String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: kFontSize12,
            fontWeight: FontWeight.w500,
            color: kBlack,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: kFontSize12, color: kBlack),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.0),
      child: Text('•', style: TextStyle(color: kPrimaryColor, fontSize: 18)),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: kFontSize12,
            color: kBlack87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    String? iconPath,
    required String label,
    required bool isPrimary,
    VoidCallback? onPressed,
  }) {
    assert(
      icon != null || iconPath != null,
      'Either icon or iconPath must be provided.',
    );
    assert(
      icon == null || iconPath == null,
      'Cannot provide both icon and iconPath.',
    );

    Widget iconWidget;
    if (iconPath != null) {
      iconWidget = SvgPicture.asset(
        iconPath,
        colorFilter: ColorFilter.mode(
          isPrimary ? kWhite : kPrimaryColor,
          BlendMode.srcIn,
        ),
        height: 18,
        width: 18,
      );
    } else {
      iconWidget = Icon(
        icon,
        color: isPrimary ? kWhite : kPrimaryColor,
        size: 18,
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: kRadius12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? kPrimaryColor : kLightBlue,
          borderRadius: kRadius12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: kFontSize12,
                fontWeight: FontWeight.w500,
                color: isPrimary ? kWhite : kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: Text(
            'Delete Property',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
          ),
          content: Text(
            'Are you sure you want to delete this property? This action cannot be undone.',
            style: GoogleFonts.roboto(),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: GoogleFonts.roboto(color: kGrey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: GoogleFonts.roboto(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _performDelete();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete() async {
    final PropertyService propertyService = PropertyService();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting property...')),
    );

    try {
      final result = await propertyService
          .deleteProperty(widget.property.propertyId.toString());

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property deleted successfully'),
            backgroundColor: kPrimaryColor,
          ),
        );
        widget.onDelete?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete property'),
            backgroundColor: kRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }

  void _showFullAddress(BuildContext context, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: Text(
            'Full Address',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
          ),
          content: Text(address, style: GoogleFonts.roboto()),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: GoogleFonts.roboto(color: kPrimaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image,
                          size: 64, color: Colors.white),
                    );
                  },
                ),
              );
            },
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
