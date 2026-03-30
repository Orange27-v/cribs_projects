import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/screens/property/widgets/property_summary_card.dart';
import 'package:cribs_arena/screens/property/widgets/property_summary_card_skeleton.dart';
import 'package:cribs_arena/screens/search/filter_bottom_sheet.dart';
import 'package:cribs_arena/widgets/widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PropertyService _propertyService = PropertyService();

  List<Property> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    // Auto-focus on search bar when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _propertyService.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    // Show loading state immediately
    setState(() {
      _isSearching = true;
    });

    // Debounce search by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Fetch all properties and filter locally
      final response = await _propertyService.getAllProperties(page: 1);
      final allProperties = response.data;

      // Filter properties based on search query
      var filteredProperties = allProperties.where((property) {
        final searchLower = query.toLowerCase();
        return property.title.toLowerCase().contains(searchLower) ||
            property.location.toLowerCase().contains(searchLower) ||
            property.type.toLowerCase().contains(searchLower) ||
            property.description.toLowerCase().contains(searchLower);
      }).toList();

      // Apply active filters if any
      if (_activeFilters != null) {
        filteredProperties = _applyFilters(filteredProperties);
      }

      if (mounted) {
        setState(() {
          _searchResults = filteredProperties;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  List<Property> _applyFilters(List<Property> properties) {
    if (_activeFilters == null) return properties;

    return properties.where((property) {
      // Filter by listing type (For Sale / For Rent)
      if (_activeFilters!['transactionType'] != null) {
        if (property.listingType != _activeFilters!['transactionType']) {
          return false;
        }
      }

      // Filter by property type
      if (_activeFilters!['propertyType'] != null) {
        if (property.type != _activeFilters!['propertyType']) {
          return false;
        }
      }

      // Filter by bedrooms
      final bedroomMin = _activeFilters!['bedroomMin'] as int?;
      final bedroomMax = _activeFilters!['bedroomMax'] as int?;
      if (bedroomMin != null && property.beds < bedroomMin) {
        return false;
      }
      if (bedroomMax != null && property.beds > bedroomMax) {
        return false;
      }

      // Filter by bathrooms
      final bathroomMin = _activeFilters!['bathroomMin'] as int?;
      final bathroomMax = _activeFilters!['bathroomMax'] as int?;
      if (bathroomMin != null && property.baths < bathroomMin) {
        return false;
      }
      if (bathroomMax != null && property.baths > bathroomMax) {
        return false;
      }

      // Filter by price range (simplified - you can enhance this)
      final priceRange = _activeFilters!['priceRange'] as String?;
      if (priceRange != null && priceRange != 'Negotiable') {
        if (!_isPriceInRange(
            property.price, priceRange, property.listingType)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _isPriceInRange(double price, String range, String listingType) {
    if (listingType == 'For Sale') {
      // Buying price ranges in Naira
      if (range == 'Under 50M') return price < 50000000;
      if (range == '50M - 500M') return price >= 50000000 && price <= 500000000;
      if (range == '500M - 5B') return price > 500000000 && price <= 5000000000;
      if (range == '5B+') return price > 5000000000;
    } else {
      // Renting price ranges (per month)
      if (range == 'Under 50K/month') return price < 50000;
      if (range == '50K - 250K/month') return price >= 50000 && price <= 250000;
      if (range == '250K - 750K/month') {
        return price > 250000 && price <= 750000;
      }
      if (range == '750K+/month') return price > 750000;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDarkTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Properties',
          style: GoogleFonts.roboto(
            fontSize: kFontSize18,
            fontWeight: FontWeight.bold,
            color: kDarkTextColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: kWhite,
            padding: const EdgeInsets.all(kSizedBoxH16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 3.0,
              ),
              decoration: BoxDecoration(
                color: kGrey.withValues(alpha: 0.1),
                borderRadius: kRadius30,
                border: Border.all(
                  color: kGrey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by name, location, or type',
                        hintStyle: GoogleFonts.roboto(
                          color: kGrey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: kGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                  // Filter Icon
                  GestureDetector(
                    onTap: () async {
                      final filters =
                          await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const FilterBottomSheet(),
                      );

                      if (filters != null) {
                        setState(() {
                          _activeFilters = filters;
                        });
                        // Re-run search with filters
                        if (_searchController.text.isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: _activeFilters != null
                          ? BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: kRadius8,
                            )
                          : null,
                      child: Icon(
                        Icons.tune,
                        color: _activeFilters != null
                            ? kPrimaryColor
                            : kPrimaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Show skeleton while searching
    if (_isSearching) {
      return GridView.builder(
        padding: const EdgeInsets.all(kSizedBoxH16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: kSizedBoxW12,
          mainAxisSpacing: kSizedBoxH12,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const PropertySummaryCardSkeleton();
        },
      );
    }

    // Show initial state (before any search)
    if (!_hasSearched) {
      return const EmptyStateWidget(
        icon: Icons.search,
        message:
            'Search for properties\nEnter a location, property name, or type',
      );
    }

    // Show "No results found" if search completed but no results
    if (_searchResults.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        message: 'No properties found\nTry searching with different keywords',
      );
    }

    // Show search results in a grid
    return GridView.builder(
      padding: const EdgeInsets.all(kSizedBoxH16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: kSizedBoxW12,
        mainAxisSpacing: kSizedBoxH12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final property = _searchResults[index];
        return PropertySummaryCard(
          property: property,
          onRemove: (_) {},
        );
      },
    );
  }
}
