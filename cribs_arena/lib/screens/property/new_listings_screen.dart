import 'package:cribs_arena/models/property.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/services/new_listing_service.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/screens/property/property_details_screen.dart';
import 'package:cribs_arena/screens/property/widgets/property_summary_card.dart';
import 'package:cribs_arena/screens/property/widgets/property_summary_card_skeleton.dart';
import 'package:flutter/material.dart';

class NewListingsScreen extends StatefulWidget {
  final List<String> agentIds;
  final double? latitude;
  final double? longitude;

  const NewListingsScreen({
    super.key,
    this.agentIds = const [],
    this.latitude,
    this.longitude,
  });

  @override
  State<NewListingsScreen> createState() => _NewListingsScreenState();
}

class _NewListingsScreenState extends State<NewListingsScreen> {
  final PropertyService _propertyService = PropertyService();
  final NewListingService _newListingService = NewListingService();
  String _searchQuery = '';
  List<Property> _listings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNewListings();
  }

  @override
  void dispose() {
    _propertyService.dispose();
    super.dispose();
  }

  Future<void> _fetchNewListings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Property> listings = [];

      if (widget.agentIds.isNotEmpty) {
        List<Property> combinedListings = [];
        for (String agentId in widget.agentIds) {
          final agentListings = await _propertyService
              .getNewPropertiesByAgentId(agentId)
              .timeout(const Duration(seconds: 15));
          combinedListings.addAll(agentListings);
        }

        combinedListings.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        listings = combinedListings;
      } else {
        double? lat = widget.latitude;
        double? lon = widget.longitude;

        if (lat == null || lon == null) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          lat = position.latitude;
          lon = position.longitude;
        }

        listings = await _newListingService
            .getNewListingsNearby(lat, lon)
            .timeout(const Duration(seconds: 15));
      }

      if (mounted) {
        setState(() {
          _listings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _filterProperties(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: kPaddingFromLTRB16_16_16_8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back,
                        color: kPrimaryColor, size: kIconSize24),
                    const SizedBox(width: kSizedBoxW8),
                    Text(
                      kBackText,
                      style: GoogleFonts.roboto(
                        color: kPrimaryColor,
                        fontSize: kFontSize16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH12),
            Padding(
              padding: kPaddingH16,
              child: Text(
                kNewListingsTitle,
                style: GoogleFonts.roboto(
                  fontSize: kFontSize16,
                  fontWeight: FontWeight.w400,
                  color: kDarkTextColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH8),
            Padding(
              padding: kPaddingH16,
              child: TextField(
                style: GoogleFonts.roboto(color: kDarkTextColor),
                onChanged: _filterProperties,
                decoration: InputDecoration(
                  hintText: kSearchPropertyHint,
                  hintStyle: GoogleFonts.roboto(color: kGrey500),
                  prefixIcon: const Icon(Icons.search, color: kGrey500),
                  filled: true,
                  fillColor: kWhite,
                  contentPadding: kPaddingV14,
                  border: const OutlineInputBorder(
                    borderRadius: kRadius12,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH12),
            Expanded(
              child: _isLoading
                  ? GridView.builder(
                      padding: kPaddingH16,
                      itemCount: 6,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        return const PropertySummaryCardSkeleton();
                      },
                    )
                  : _error != null
                      ? NetworkErrorWidget(
                          errorMessage: _error,
                          onRefresh: _fetchNewListings,
                        )
                      : _buildListingsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsContent() {
    final filteredListings = _searchQuery.isEmpty
        ? _listings
        : _listings
            .where((property) =>
                property.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                property.location
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                property.type
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    if (filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleImageContainer(
              imagePath: 'assets/images/magnifier.png',
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'No new listings found.',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: kGrey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNewListings,
      child: GridView.builder(
        padding: kPaddingH16,
        itemCount: filteredListings.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final property = filteredListings[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsScreen(property: property),
              ),
            ),
            child: PropertySummaryCard(
              property: property,
              onRemove: (_) {},
            ),
          );
        },
      ),
    );
  }
}
