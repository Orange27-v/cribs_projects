import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/services/recommended_property_service.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/screens/property/property_details_screen.dart'; // Added this import
import 'package:cribs_arena/screens/property/widgets/property_summary_card.dart';
import 'package:cribs_arena/screens/property/widgets/property_summary_card_skeleton.dart';
import 'package:flutter/material.dart';

class RecommendedPropertyScreen extends StatefulWidget {
  const RecommendedPropertyScreen({
    super.key,
  });

  @override
  State<RecommendedPropertyScreen> createState() =>
      _RecommendedPropertyScreenState();
}

class _RecommendedPropertyScreenState extends State<RecommendedPropertyScreen> {
  String searchQuery = '';
  List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;

  final RecommendedPropertyService _recommendedPropertyService =
      RecommendedPropertyService();

  @override
  void initState() {
    super.initState();
    _fetchRecommendedProperties();
  }

  @override
  void dispose() {
    _recommendedPropertyService.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendedProperties() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final properties = await _recommendedPropertyService
          .getRecommendedProperties(
            position.latitude,
            position.longitude,
          )
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _properties = properties;
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
      searchQuery = query;
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
            // header with back
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

            // title
            Padding(
              padding: kPaddingH16,
              child: Text(
                kRecommendedPropertiesTitle,
                style: GoogleFonts.roboto(
                  fontSize: kFontSize16,
                  fontWeight: FontWeight.w400,
                  color: kDarkTextColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH8),

            // search
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

            // Recommended Properties List
            Expanded(
              child: _isLoading
                  ? _buildSkeletonList()
                  : _error != null
                      ? _buildErrorView(_error!)
                      : _buildPropertiesContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return GridView.builder(
      padding: kPaddingH16,
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return const PropertySummaryCardSkeleton();
      },
    );
  }

  Widget _buildErrorView(String error) {
    return NetworkErrorWidget(
      errorMessage: error,
      onRefresh: _fetchRecommendedProperties,
    );
  }

  Widget _buildEmptyView() {
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
            searchQuery.isNotEmpty
                ? 'No properties found matching "$searchQuery"'
                : 'No recommended properties found.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: kFontSize16,
              color: kGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesContent() {
    final filteredProperties = searchQuery.isEmpty
        ? _properties
        : _properties
            .where((property) =>
                property.title
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                property.location
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                property.type.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    if (filteredProperties.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _fetchRecommendedProperties,
      child: _buildPropertiesList(filteredProperties),
    );
  }

  Widget _buildPropertiesList(List<Property> properties) {
    return GridView.builder(
      padding: kPaddingH16,
      itemCount: properties.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final property = properties[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsScreen(property: property),
              ),
            );
          },
          child: PropertySummaryCard(
            property: property,
            onRemove: (_) {},
          ),
        );
      },
    );
  }
}
