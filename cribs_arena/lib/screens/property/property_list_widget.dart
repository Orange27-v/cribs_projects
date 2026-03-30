import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/services/saved_property_service.dart';
import 'package:cribs_arena/screens/components/back_navigator.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../constants.dart';
import '../../models/listed_property.dart';
import 'widgets/property_list_item.dart';
import 'widgets/property_list_item_skeleton.dart';

class PropertyListWidget extends StatefulWidget {
  final List<ListedProperty> properties;
  final String title;
  final String searchHint;
  final VoidCallback? onBackPressed;
  final Function(String)? onSearchChanged;
  final Function(ListedProperty)? onPropertyTap;
  final bool showHeader;
  final bool isLoading; // Add loading parameter

  const PropertyListWidget({
    super.key,
    required this.properties,
    required this.title,
    this.searchHint = kSearchPropertyHint,
    this.onBackPressed,
    this.onSearchChanged,
    this.onPropertyTap,
    this.showHeader = true,
    this.isLoading = false, // Default to false
  });

  @override
  State<PropertyListWidget> createState() => _PropertyListWidgetState();
}

class _PropertyListWidgetState extends State<PropertyListWidget> {
  late List<ListedProperty> _filteredProperties;
  late List<ListedProperty> _allProperties;
  final PropertyService _propertyService = PropertyService();
  final SavedPropertyService _savedPropertyService = SavedPropertyService();
  final bool _isInternalLoading = false;

  @override
  void initState() {
    super.initState();
    _allProperties = List<ListedProperty>.from(widget.properties);
    _filteredProperties = _allProperties;
  }

  @override
  void didUpdateWidget(PropertyListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update properties if they change from parent
    if (oldWidget.properties != widget.properties) {
      _allProperties = List<ListedProperty>.from(widget.properties);
      _filteredProperties = _allProperties;
    }
  }

  @override
  void dispose() {
    _propertyService.dispose();
    super.dispose();
  }

  bool get _isLoading => widget.isLoading || _isInternalLoading;

  void _filterProperties(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredProperties = _allProperties
          .where((p) =>
              p.title.toLowerCase().contains(lowerCaseQuery) ||
              p.location.toLowerCase().contains(lowerCaseQuery) ||
              p.type.toLowerCase().contains(lowerCaseQuery))
          .toList();
    });
    widget.onSearchChanged?.call(query);
  }

  Future<void> _toggleBookmark(ListedProperty property) async {
    final originalBookmarkedStatus = property.isBookmarked;

    // Optimistically update UI
    _updatePropertyBookmarkStatus(property, !originalBookmarkedStatus);

    try {
      if (originalBookmarkedStatus) {
        await _savedPropertyService.unsaveProperty(property.id);
      } else {
        await _savedPropertyService.saveProperty(property.id);
      }
    } on NetworkException catch (e) {
      // Revert UI on error
      _updatePropertyBookmarkStatus(property, originalBookmarkedStatus);

      if (!mounted) return;

      String message = 'Failed to update bookmark';
      if (e.isAuthError) {
        message = 'Please log in to bookmark properties';
      } else if (e.isConnectionError) {
        message = 'No internet connection';
      }

      SnackbarHelper.showError(
        context,
        message,
      );
    } catch (e) {
      // Revert UI on error
      _updatePropertyBookmarkStatus(property, originalBookmarkedStatus);

      if (!mounted) return;

      SnackbarHelper.showError(context, 'Failed to update bookmark: $e');
    }
  }

  void _updatePropertyBookmarkStatus(ListedProperty property, bool newStatus) {
    setState(() {
      final indexAll = _allProperties.indexWhere((p) => p.id == property.id);
      if (indexAll != -1) {
        _allProperties[indexAll] =
            _allProperties[indexAll].copyWith(isBookmarked: newStatus);
      }

      final indexFiltered =
          _filteredProperties.indexWhere((p) => p.id == property.id);
      if (indexFiltered != -1) {
        _filteredProperties[indexFiltered] = _filteredProperties[indexFiltered]
            .copyWith(isBookmarked: newStatus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) _buildHeader(context),
            if (widget.showHeader) _buildTitle(),
            const SizedBox(height: kSizedBoxH16),
            _buildSearchBar(),
            const SizedBox(height: kSizedBoxH24),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Skeletonizer(
      enabled: _isLoading,
      child: Padding(
        padding: kPaddingH16,
        child: Text(
          widget.title,
          style: GoogleFonts.roboto(
            fontSize: kFontSize18,
            fontWeight: FontWeight.w400,
            color: kBlack87,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Skeletonizer(
      enabled: _isLoading,
      child: Padding(
        padding: kPaddingH16,
        child: TextField(
          onChanged: _isLoading ? null : _filterProperties,
          enabled: !_isLoading,
          style: GoogleFonts.roboto(color: kBlack87, fontSize: kFontSize14),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            hintStyle: GoogleFonts.roboto(color: kGrey, fontSize: kFontSize14),
            prefixIcon:
                const Icon(Icons.search, color: kGrey, size: kIconSize22),
            filled: true,
            fillColor: kGreyOpacity01,
            contentPadding: kPaddingV15,
            border: const OutlineInputBorder(
              borderRadius: kRadius12,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    } else if (_filteredProperties.isEmpty) {
      return _buildEmptyState();
    }
    return _buildPropertyListView();
  }

  Widget _buildLoadingSkeleton() {
    return Expanded(
      child: ListView.builder(
        itemCount: 5, // Show 5 skeleton items
        padding: kPaddingH16,
        itemBuilder: (context, index) {
          return const Padding(
            padding: kPaddingOnlyBottom16,
            child: PropertyListItemSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildPropertyListView() {
    return Expanded(
      child: ListView.builder(
        itemCount: _filteredProperties.length,
        padding: kPaddingH16,
        itemBuilder: (context, index) {
          final property = _filteredProperties[index];
          return Padding(
            padding: kPaddingOnlyBottom16,
            child: GestureDetector(
              onTap: () => widget.onPropertyTap?.call(property),
              child: PropertyListItem(
                property: property,
                onBookmarkTap: () => _toggleBookmark(property),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleImageContainer(
              imagePath: 'assets/images/magnifier.png',
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              kNoPropertiesFoundText,
              style: GoogleFonts.roboto(
                fontSize: kFontSize18,
                fontWeight: FontWeight.w500,
                color: kBlack54,
              ),
            ),
            const SizedBox(height: kSizedBoxH8),
            Text(
              kAdjustSearchCriteriaText,
              style: GoogleFonts.roboto(fontSize: kFontSize14, color: kGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: kPaddingFromLTRB8_16_16_8,
      child: BackNavigator(),
    );
  }
}
