import 'package:cribs_agents/models/property.dart';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/screens/properties/edit_property_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ViewPropertyScreen extends StatefulWidget {
  final Property property;

  const ViewPropertyScreen({super.key, required this.property});

  @override
  State<ViewPropertyScreen> createState() => _ViewPropertyScreenState();
}

class _ViewPropertyScreenState extends State<ViewPropertyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<String> get propertyImages => widget.property.images ?? [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onImageTap() {
    if (propertyImages.isNotEmpty) {
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
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '$kMainBaseUrl/storage/property_images/$path';
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      body: Stack(
        children: [
          _buildImageSlider(),
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: kBlack.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: kWhite, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: kBlack.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.share, color: kWhite, size: 20),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPropertyScreen(
                        property: widget.property,
                      ),
                    ),
                  );
                  // Refresh if property was updated
                  if (!context.mounted) return;
                  if (result == true) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kBlack.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 8),
                      _buildLocation(),
                      const SizedBox(height: 16),
                      _buildStatusBadges(),
                      const Divider(height: 40, thickness: 0.5),
                      _buildPricingSection(),
                      const Divider(height: 40, thickness: 0.5),
                      _buildAboutSection(),
                      const Divider(height: 40, thickness: 0.5),
                      _buildFeaturesSection(),
                      const Divider(height: 40, thickness: 0.5),
                      _buildAmenitiesSection(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    if (propertyImages.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.45,
        width: double.infinity,
        color: kGrey400,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: kGrey),
        ),
      );
    }

    return GestureDetector(
      onTap: _onImageTap,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: propertyImages.length,
              itemBuilder: (context, index) {
                // Use NetworkImage for backend images
                return Image.network(
                  _getImageUrl(propertyImages[index]),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: kGrey400,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64, color: kGrey),
                      ),
                    );
                  },
                );
              },
            ),
            if (propertyImages.length > 1)
              Positioned(bottom: 16.0, child: _buildPageIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        propertyImages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? kPrimaryColor
                : kWhite.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.property.title,
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kBlack,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.property.listingType == 'For Sale'
                ? kPrimaryColor
                : kOrange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.property.listingType,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: kGrey, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.property.address ?? widget.property.location,
            style: GoogleFonts.roboto(fontSize: 14, color: kGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadges() {
    return Wrap(
      spacing: 8,
      children: [
        _buildBadge(
          widget.property.status,
          widget.property.status == 'Active' ? kGreen : kRed,
        ),
        _buildBadge(widget.property.type, kPrimaryColor),
        if (widget.property.isFeatured) _buildBadge('Featured', kOrange),
        if (widget.property.isVerified) _buildBadge('Verified', kGreen),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Property Price',
              style: GoogleFonts.roboto(fontSize: 15, color: kGrey),
            ),
            Text(
              _formatPrice(widget.property.price),
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
        // Inspection fee removed - agents cannot set this
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this property',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.property.description ??
              'No description provided for this property.',
          style: GoogleFonts.roboto(
            fontSize: 15,
            color: kBlack87,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFeatureIcon(
              '${widget.property.beds}',
              'Beds',
              Icons.king_bed_outlined,
            ),
            _buildFeatureIcon(
              '${widget.property.baths}',
              'Baths',
              Icons.bathtub_outlined,
            ),
            _buildFeatureIcon(
              widget.property.sqft ?? '-',
              'Sq ft',
              Icons.square_foot_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: kLightBlue,
            borderRadius: kRadius12,
          ),
          child: Icon(icon, color: kPrimaryColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.roboto(fontSize: 14, color: kGrey)),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    if (widget.property.amenities == null ||
        widget.property.amenities!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: kBlack,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.property.amenities!.map((amenity) {
            return Chip(
              label: Text(amenity),
              backgroundColor: kLightBlue,
              labelStyle: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kPrimaryColor,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
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
                      child: Icon(Icons.broken_image, size: 64, color: kWhite),
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
