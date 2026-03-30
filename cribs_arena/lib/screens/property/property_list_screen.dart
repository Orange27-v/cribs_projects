import 'dart:async';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/screens/property/property_details_screen.dart'; // Added this import
import 'package:cribs_arena/screens/property/widgets/property_summary_card.dart';
import 'package:cribs_arena/screens/property/widgets/property_summary_card_skeleton.dart';
import 'package:flutter/material.dart';

class PropertyListScreen extends StatefulWidget {
  final String? agentId;
  final String? agentName;

  const PropertyListScreen({super.key, this.agentId, this.agentName});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final PropertyService _propertyService = PropertyService();
  late StreamController<List<Property>> _streamController;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<Property>>.broadcast();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      List<Property> fetchedProperties;

      if (widget.agentId != null) {
        debugPrint(
            'PropertyListScreen: Fetching properties for agentId: ${widget.agentId}');
        fetchedProperties =
            await _propertyService.getPropertiesByAgentId(widget.agentId!);
        debugPrint(
            'PropertyListScreen: Fetched ${fetchedProperties.length} properties for agent ${widget.agentId}');
      } else {
        debugPrint(
            'PropertyListScreen: Fetching all properties (agentId is null)');
        final response = await _propertyService.getAllProperties();
        fetchedProperties = response.data;
        debugPrint(
            'PropertyListScreen: Fetched ${fetchedProperties.length} total properties');
      }

      if (!_streamController.isClosed) {
        _streamController.add(fetchedProperties);
      }
    } on Exception catch (e) {
      if (!_streamController.isClosed) {
        _streamController.addError(getErrorMessage(e));
        debugPrint('PropertyListScreen: Error fetching properties: $e');
      }
    }
  }

  void _filterProperties(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  void dispose() {
    _streamController.close();
    _propertyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String screenTitle = widget.agentId != null
        ? (widget.agentName != null
            ? "Properties by ${widget.agentName}"
            : 'Agent Properties')
        : 'All Properties';

    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
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

            // Screen title
            Padding(
              padding: kPaddingH16,
              child: Text(
                screenTitle,
                style: GoogleFonts.roboto(
                  fontSize: kFontSize16,
                  fontWeight: FontWeight.w400,
                  color: kDarkTextColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH8),

            // Search bar
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

            // Properties List
            Expanded(
              child: StreamBuilder<List<Property>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorView(snapshot.error.toString());
                  }

                  if (!snapshot.hasData) {
                    return _buildSkeletonList();
                  }

                  final originalProperties = snapshot.data!;
                  final properties = searchQuery.isEmpty
                      ? originalProperties
                      : originalProperties
                          .where((property) =>
                              property.title
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ||
                              property.location
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()) ||
                              property.type
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()))
                          .toList();

                  if (properties.isEmpty) {
                    return _buildEmptyView();
                  }

                  return RefreshIndicator(
                    onRefresh: _fetchProperties,
                    child: _buildPropertiesList(properties),
                  );
                },
              ),
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
      onRefresh: _fetchProperties,
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
            widget.agentId != null
                ? 'No properties listed by this agent yet.'
                : searchQuery.isNotEmpty
                    ? 'No properties found matching "$searchQuery"'
                    : 'No properties found.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: kFontSize16,
              color: kGrey,
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _filterProperties('');
              },
              child: Text(
                'Clear search',
                style: GoogleFonts.roboto(
                  color: kPrimaryColor,
                  fontSize: kFontSize14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
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
