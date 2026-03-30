import 'package:cribs_agents/screens/map/user_info_popup.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constants.dart';

import '../map/map_screen.dart';
import '../map/glow_loading_widget.dart';
import 'package:cribs_agents/screens/agents/user_widgets/map_controls.dart';
import '../../services/map_service.dart';
import 'package:geolocator/geolocator.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  Map<String, dynamic>? _selectedAgent;

  // Animation controllers for popup
  late AnimationController _popupAnimationController;
  late AnimationController _closeButtonAnimationController;

  // Holds users to be displayed on the map
  List<Map<String, dynamic>> _users = [];
  LatLng? _initialMapCenter;
  LatLng? _currentCenter;
  bool _isSearching = false;
  bool _isFetchingUsers = false;
  int _selectedTabIndex = 0; // 0: Active, 1: My Dashboard
  Timer? _mapMoveDebounce;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _popupAnimationController = AnimationController(
      duration: kDuration300ms,
      vsync: this,
    );

    _closeButtonAnimationController = AnimationController(
      duration: kDuration150ms,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndLoadUsers(); // Initial call to find users
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _mapMoveDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _popupAnimationController.dispose();
    _closeButtonAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When the app is resumed, refresh the map to ensure markers are visible
      if (_users.isNotEmpty && mounted) {
        _mapController.updateUserPositions();
      }
    }
  }

  void _onAgentSelected(Map<String, dynamic> agent) {
    if (!mounted) return;

    setState(() {
      _selectedAgent = agent;
    });
    // Animate popup in
    _popupAnimationController.forward();
  }

  void _dismissAgentPopup() {
    if (!mounted) return;

    // Animate popup out
    _popupAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedAgent = null;
        });
      }
    });
  }

  void _onMapMoved(LatLng center) {
    _currentCenter = center;

    // Debounce automatic fetching (only fetch if user stops for 5 seconds)
    _mapMoveDebounce?.cancel();
    _mapMoveDebounce = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('🗺️ Auto-fetching users after 5s idle at: $center');
        _fetchUsers(center, isAutoFetch: true);
      }
    });
  }

  /// Enhanced user search with glow loading
  Future<void> _findNearbyClients() async {
    _mapMoveDebounce?.cancel();

    if (_currentCenter == null && _initialMapCenter != null) {
      _currentCenter = _initialMapCenter;
    }

    if (_currentCenter != null) {
      debugPrint('🔍 Manual fetch at current map center: $_currentCenter');
      await _fetchUsers(_currentCenter!, isAutoFetch: false);
    } else {
      // Fall back to initial location fetch
      await _initLocationAndLoadUsers();
    }
  }

  Future<void> _initLocationAndLoadUsers() async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _selectedAgent = null;
      _users = [];
    });

    _popupAnimationController.reset();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _initialMapCenter = LatLng(position.latitude, position.longitude);
      _currentCenter = _initialMapCenter;

      if (!mounted) return;

      await _fetchUsers(_initialMapCenter!, isAutoFetch: false);
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _fetchUsers(LatLng center, {required bool isAutoFetch}) async {
    if (!mounted || _isFetchingUsers) return;

    _isFetchingUsers = true;

    // Only show loading overlay for manual fetches
    if (!isAutoFetch) {
      setState(() {
        _isSearching = true;
        _selectedAgent = null;
      });
      _popupAnimationController.reset();
    }

    try {
      debugPrint(
          '🔄 Fetching users at: ${center.latitude}, ${center.longitude}');

      final foundUsers = await _mapService
          .getNearbyUsers(
            latitude: center.latitude,
            longitude: center.longitude,
            radius: kDefaultSearchRadius,
          )
          .timeout(
            kApiTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      if (!mounted) return;

      debugPrint('✅ Fetched ${foundUsers.length} users');

      // Only update if users actually changed
      if (_usersChanged(foundUsers)) {
        debugPrint('📦 Users list changed, updating UI');
        setState(() {
          _users = foundUsers;
          _currentCenter = center;
        });
      } else {
        debugPrint('📦 Same users, skipping UI update');
        _currentCenter = center;
      }

      // Give time for state to update, then refresh markers
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        _mapController.refreshUsersFully();
      }

      // Show feedback if no results on manual fetch
      if (foundUsers.isEmpty && !isAutoFetch && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No clients found within 50km radius'),
            backgroundColor: kOrange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      if (mounted) {
        setState(() {
          _users = [];
        });

        // Determine user-friendly error message
        String errorMessage = 'Failed to load clients';
        if (e is TimeoutException) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('Unauthorized') ||
            e.toString().contains('401')) {
          errorMessage = 'Session expired. Please log in again.';
        } else if (e.toString().contains('No authentication token')) {
          errorMessage = 'Please log in to continue.';
        } else if (e.toString().contains('Location')) {
          errorMessage = 'Location permission required to find nearby clients.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: kRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _isFetchingUsers = false;
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  /// Check if user list actually changed to prevent unnecessary rebuilds
  bool _usersChanged(List<Map<String, dynamic>> newUsers) {
    if (_users.length != newUsers.length) return true;

    final oldIds = _users.map((u) => u['id']?.toString() ?? '').toSet();
    final newIds = newUsers.map((u) => u['id']?.toString() ?? '').toSet();

    return !oldIds.containsAll(newIds) || !newIds.containsAll(oldIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: _initialMapCenter == null
                        ? Container() // Empty container while loading
                        : Padding(
                            padding: kPaddingOnlyTop4,
                            child: MapScreen(
                              controller: _mapController,
                              users: _users,
                              onUserSelected: _onAgentSelected,
                              onMapMoved: _onMapMoved,
                              initialCenter: _initialMapCenter!,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Top Section: Switcher & Primary Button
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildSwitcher(),
            ),
            Positioned(
              bottom: 65, // Position above the bottom nav bar or safe area
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedFloatingActionButton(
                  onPressed: _findNearbyClients,
                  isLoading: _isSearching,
                  customText: 'Find Nearby Clients',
                  customIcon: Icons.person_search,
                ),
              ),
            ),

            // Glow loading animation overlay
            if (_isSearching)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: kBlackOpacity08,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        LocationPulseWidget(
                          isVisible: true,
                          pulseColor: kCyan,
                          size: MediaQuery.of(context).size.width,
                        ),
                        const Positioned(
                          bottom: 100.0,
                          child: Text(
                            'Searching for clients nearby...',
                            style: TextStyle(
                              color: kWhite,
                              fontSize: kFontSize14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Agent info popup - positioned over the map
            if (_selectedAgent != null && !_isSearching)
              AgentInfoPopup(
                selectedAgent: _selectedAgent!,
                onDismiss: _dismissAgentPopup,
                popupAnimationController: _popupAnimationController,
                closeButtonAnimationController: _closeButtonAnimationController,
              ),

            // Optional: Add refresh button (Removed in favor of PrimaryButton)
            /*
            Positioned(
              top: kPaddingAll16.top,
              right: kPaddingAll16.right,
              child: _MapIconButton(
                icon: Icons.refresh,
                onPressed: _isSearching ? () {} : _findAgentsOnMap,
              ),
            ),
            */

            // Find Nearby Clients Button (Moved to top)
            /*
            Positioned(
              bottom: 120,
              left: 16,
              child: FloatingActionButton.extended(
                onPressed: _isSearching ? null : _findAgentsOnMap,
                backgroundColor: kPrimaryColor,
                icon: const Icon(Icons.person_search, color: kWhite),
                label: const Text(
                  'Find Nearby Clients',
                  style: TextStyle(color: kWhite),
                ),
              ),
            ),
            */

            // Map Controls (Location & Zoom)
            Positioned(
              bottom: 150,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // My Location Button
                  MapIconButton(
                    icon: Icons.my_location,
                    onPressed: () {
                      _mapController.centerToMyLocation();
                    },
                  ),
                  const SizedBox(height: 6),

                  // Zoom Controls
                  MapZoomControls(
                    onZoomIn: () => _mapController.zoomIn(),
                    onZoomOut: () => _mapController.zoomOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem('Active', 0),
          _buildTabItem('My Dashboard', 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: kDuration200ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? kWhite : kBlack87,
              fontWeight: FontWeight.w600,
              fontSize: kFontSize14,
            ),
          ),
        ),
      ),
    );
  }
}
