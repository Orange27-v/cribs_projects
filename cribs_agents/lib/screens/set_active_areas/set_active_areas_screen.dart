import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/active_areas_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/screens/map/map_section_widget.dart';
import 'package:cribs_agents/screens/map/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SetActiveAreasScreen extends StatefulWidget {
  const SetActiveAreasScreen({super.key});

  @override
  State<SetActiveAreasScreen> createState() => _SetActiveAreasScreenState();
}

class _SetActiveAreasScreenState extends State<SetActiveAreasScreen> {
  final ActiveAreasService _activeAreasService = ActiveAreasService();
  final TextEditingController _areaController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _activeAreas = [];
  List<PlaceSuggestion> _suggestions = [];

  // Map control
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isUpdatingLocation = false;
  LatLng _initialMapCenter = const LatLng(6.5244, 3.3792); // Lagos default

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSearching = false;
  bool _showSuggestions = false;
  String? _errorMessage;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchActiveAreas();
    _areaController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _areaController.removeListener(_onSearchChanged);
    _areaController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      // Delay hiding suggestions to allow tap on suggestion
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();

    final query = _areaController.text.trim();

    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final suggestions = await _activeAreasService.getPlaceSuggestions(query);

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isSearching = false;
      });
    }
  }

  Future<void> _fetchActiveAreas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _activeAreasService.getActiveAreas();

    if (mounted) {
      if (result['success'] == true) {
        _activeAreas = List<String>.from(result['active_areas'] ?? []);

        // Set initial map center from agent data if available
        final agentInfo = result['data'];
        bool hasSavedLocation = false;

        if (agentInfo != null) {
          final lat = agentInfo['latitude'];
          final lng = agentInfo['longitude'];
          if (lat != null && lng != null) {
            final latVal = double.tryParse(lat.toString());
            final lngVal = double.tryParse(lng.toString());
            if (latVal != null && lngVal != null) {
              _initialMapCenter = LatLng(latVal, lngVal);
              _selectedLocation = _initialMapCenter;
              hasSavedLocation = true;
            }
          }
        }

        // If no saved location, try to get current device location
        if (!hasSavedLocation) {
          try {
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (serviceEnabled) {
              LocationPermission permission =
                  await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }

              if (permission == LocationPermission.whileInUse ||
                  permission == LocationPermission.always) {
                final position = await Geolocator.getCurrentPosition();
                _initialMapCenter =
                    LatLng(position.latitude, position.longitude);
                // Don't set _selectedLocation here so user explicitly selects it
              }
            }
          } catch (e) {
            debugPrint('Error getting current location: $e');
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'];
        });
      }
    }
  }

  Future<void> _updateAgentLocation() async {
    if (_selectedLocation == null) {
      _showSnackBar('Please select a location on the map', isError: true);
      return;
    }

    setState(() {
      _isUpdatingLocation = true;
    });

    final result = await _activeAreasService.updateLocation(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );

    if (mounted) {
      setState(() {
        _isUpdatingLocation = false;
      });

      if (result['success'] == true) {
        _showSnackBar('Current location updated successfully!', isError: false);
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update location',
            isError: true);
      }
    }
  }

  void _addAreaFromSuggestion(PlaceSuggestion suggestion) {
    final areaName = suggestion.mainText;

    if (!_activeAreas.contains(areaName)) {
      if (_activeAreas.length >= 20) {
        _showSnackBar('Maximum of 20 areas allowed', isError: true);
        return;
      }

      setState(() {
        _activeAreas.add(areaName);
        _areaController.clear();
        _suggestions = [];
        _showSuggestions = false;
      });
    } else {
      _showSnackBar('Area already added', isError: true);
    }

    _searchFocusNode.unfocus();
  }

  void _addAreaManually() {
    final area = _areaController.text.trim();

    if (area.isEmpty) {
      return;
    }

    if (_activeAreas.contains(area)) {
      _showSnackBar('Area already added', isError: true);
      return;
    }

    if (_activeAreas.length >= 20) {
      _showSnackBar('Maximum of 20 areas allowed', isError: true);
      return;
    }

    setState(() {
      _activeAreas.add(area);
      _areaController.clear();
      _suggestions = [];
      _showSuggestions = false;
    });

    _searchFocusNode.unfocus();
  }

  void _removeArea(String area) {
    setState(() {
      _activeAreas.remove(area);
    });
  }

  Future<void> _saveActiveAreas() async {
    if (_activeAreas.isEmpty) {
      _showSnackBar('Please add at least one area', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await _activeAreasService.setActiveAreas(_activeAreas);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result['success'] == true) {
        _showSnackBar('Active areas updated successfully!', isError: false);
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update active areas',
            isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Set Areas',
          style: GoogleFonts.roboto(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: PrimaryButton(
                text: _isSaving ? 'Saving...' : 'Confirm',
                onPressed: _isSaving ? null : _saveActiveAreas,
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading active areas',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchActiveAreas,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current areas count header
            _buildCurrentAreasHeader(),
            const SizedBox(height: 16),

            // Search input with autocomplete
            _buildSearchInput(),

            // Suggestions dropdown
            if (_showSuggestions) _buildSuggestionsDropdown(),

            const SizedBox(height: 24),

            // Section title
            Text(
              'Your Active Areas',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kGrey600,
              ),
            ),
            const SizedBox(height: 12),

            // Active areas chips
            _activeAreas.isEmpty
                ? _buildEmptyState()
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _activeAreas.map((area) {
                      return _buildAreaChip(area);
                    }).toList(),
                  ),

            const SizedBox(height: 24),

            // Map Section
            Text(
              'Your Current Location',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kGrey600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drag the map to set your precise operating location',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: kGrey500,
              ),
            ),
            const SizedBox(height: 12),

            // Current Location Map
            MapSectionWidget(
              controller: _mapController,
              initialCenter: _initialMapCenter,
              onMapMoved: (center) {
                setState(() {
                  _selectedLocation = center;
                });
              },
            ),

            const SizedBox(height: 16),

            // Update Location Button
            SizedBox(
              width: double.infinity,
              child: OutlinedActionButton(
                onPressed: _isUpdatingLocation ? null : _updateAgentLocation,
                iconWidget: _isUpdatingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kPrimaryColor))
                    : null,
                icon: _isUpdatingLocation ? null : Icons.gps_fixed_rounded,
                text: _isUpdatingLocation
                    ? 'Updating...'
                    : 'Set as My Current Location',
                borderWidth: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAreasHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kGrey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Active Areas',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kGrey600,
                ),
              ),
            ],
          ),
          RichText(
            text: TextSpan(
              style: GoogleFonts.roboto(fontSize: 14, color: kGrey600),
              children: [
                TextSpan(
                  text: '${_activeAreas.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                TextSpan(
                  text: '/20',
                  style: const TextStyle(color: kGrey400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Area',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kGrey600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _areaController,
                  focusNode: _searchFocusNode,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kBlack87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search city, state or area...',
                    hintStyle: GoogleFonts.roboto(
                      color: kGrey400,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: kWhite,
                    prefixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kPrimaryColor,
                              ),
                            ),
                          )
                        : Icon(Icons.search_rounded, color: kGrey400, size: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: kPrimaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (_) => _addAreaManually(),
                  textInputAction: TextInputAction.done,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              width: 52,
              child: ElevatedButton(
                onPressed: _addAreaManually,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: kPrimaryColor.withValues(alpha: 0.3),
                ),
                child: const Icon(Icons.add_rounded, color: kWhite, size: 26),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionsDropdown() {
    if (_suggestions.isEmpty && !_isSearching) {
      if (_areaController.text.trim().length >= 2) {
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: kGrey400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No areas found. Press + to add manually.',
                  style: GoogleFonts.roboto(
                    color: kGrey500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          final isAlreadyAdded = _activeAreas.contains(suggestion.mainText);

          return ListTile(
            leading: Icon(
              Icons.location_on_outlined,
              color: isAlreadyAdded ? kGrey400 : kPrimaryColor,
              size: 20,
            ),
            title: Text(
              suggestion.mainText,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isAlreadyAdded ? kGrey400 : kBlack87,
              ),
            ),
            subtitle: suggestion.secondaryText.isNotEmpty
                ? Text(
                    suggestion.secondaryText,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: kGrey500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: isAlreadyAdded
                ? SvgPicture.asset(
                    'assets/icons/success.svg',
                    height: 20,
                    width: 20,
                  )
                : const Icon(Icons.add_circle_outline,
                    color: kPrimaryColor, size: 20),
            onTap: isAlreadyAdded
                ? null
                : () => _addAreaFromSuggestion(suggestion),
            enabled: !isAlreadyAdded,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64,
            color: kGrey300,
          ),
          const SizedBox(height: 16),
          Text(
            'No active areas yet',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kGrey500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search and add areas where you operate',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: kGrey400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChip(String area) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 16,
            color: kPrimaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            area,
            style: GoogleFonts.roboto(
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeArea(area),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: kPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
