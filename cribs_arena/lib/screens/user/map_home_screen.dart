import 'dart:async';
import 'package:cribs_arena/screens/map/map_screen.dart';
import 'package:cribs_arena/screens/map/map_fullscreen_page.dart';
import 'package:cribs_arena/screens/map/quick_search_tags_widget.dart';
import 'package:cribs_arena/screens/user/user_widgets/glow_loading_widget.dart';
import 'package:cribs_arena/screens/search/searchbar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants.dart';
import '../../services/api_service.dart';
import '../agents/agent_info_popup.dart';
import '../agents/agent_profile_bottom_sheet.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/models/agent.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();

  LatLng? _initialMapCenter;
  List<Agent> _agents = [];
  Agent? _selectedAgent;

  LatLng? _currentCenter;

  bool _isFabVisible = false;
  bool _isSearching = false;
  bool _isFetchingAgents = false;

  late AnimationController _popupController;
  late AnimationController _closeButtonController;
  Timer? _debounceTimer;
  Timer? _mapMoveDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _popupController =
        AnimationController(vsync: this, duration: kDuration300ms);
    _closeButtonController =
        AnimationController(vsync: this, duration: kDuration150ms);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initLocationAndLoadAgents());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapMoveDebounce?.cancel();
    _popupController.dispose();
    _closeButtonController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _agents.isNotEmpty) {
      _mapController.updateAgentPositions();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_agents.isNotEmpty) {
      _mapController.updateAgentPositions();
    }
  }

  void _onAgentSelected(Agent agent) {
    setState(() => _selectedAgent = agent);
    _popupController.forward();
  }

  void _closePopup() {
    _popupController.reverse().then((_) {
      if (mounted) setState(() => _selectedAgent = null);
    });
  }

  void _onMapMoved(LatLng center) {
    // Update current center immediately for button to use
    _currentCenter = center;

    // Debounce automatic fetching (only fetch if user stops for 5 seconds)
    _mapMoveDebounce?.cancel();
    _mapMoveDebounce = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('🗺️ Auto-fetching agents after 5s idle at: $center');
        _fetchAgents(center, isAutoFetch: true);
      }
    });
  }

  Future<void> _initLocationAndLoadAgents() async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _isSearching = false);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isSearching = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _initialMapCenter = LatLng(pos.latitude, pos.longitude);
      _currentCenter = _initialMapCenter;
      await _fetchAgents(_initialMapCenter!, isAutoFetch: false);
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchAgents(LatLng center, {required bool isAutoFetch}) async {
    if (!mounted || _isFetchingAgents) return;

    _isFetchingAgents = true;

    // Only show loading overlay for manual fetches (button clicks)
    if (!isAutoFetch) {
      setState(() {
        _isSearching = true;
        _selectedAgent = null;
      });
      _popupController.reset();
    }

    try {
      debugPrint(
          '🔄 Fetching agents at: ${center.latitude}, ${center.longitude}');

      final found = await _apiService
          .getAgents(center.latitude, center.longitude)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⚠️ Agent fetch timed out after 30 seconds');
          return <Agent>[];
        },
      );

      if (!mounted) return;

      debugPrint('✅ Fetched ${found.length} agents');

      // Only update if agents actually changed to prevent unnecessary rebuilds
      if (_agentsChanged(found)) {
        debugPrint('📦 Agents list changed, updating UI');
        setState(() {
          _agents = found;
          _currentCenter = center;
        });
      } else {
        debugPrint('📦 Same agents, skipping UI update');
        _currentCenter = center;
        if (mounted) {
          setState(() {}); // Just update center without triggering full rebuild
        }
      }

      // Give time for state to update, then refresh markers
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        _mapController.refreshAgentsFully();
      }

      // Note: _isSearching will be set to false by _onMarkersReady callback
      // This ensures the glow stays visible until markers are actually positioned
    } catch (e) {
      debugPrint('❌ Error loading agents: $e');
      if (mounted) {
        setState(() {
          _agents = [];
          _isSearching = false;
        });
      }
    } finally {
      _isFetchingAgents = false;
      if (mounted) {
        setState(() {
          _isFabVisible = true;
          // Don't set _isSearching = false here anymore
          // Let the onMarkersReady callback handle it
        });
      }
    }
  }

  /// Check if agent list actually changed to prevent unnecessary rebuilds
  bool _agentsChanged(List<Agent> newAgents) {
    if (_agents.length != newAgents.length) return true;

    final oldIds = _agents.map((a) => a.id).toSet();
    final newIds = newAgents.map((a) => a.id).toSet();

    return !oldIds.containsAll(newIds) || !newIds.containsAll(oldIds);
  }

  /// Fetch agents at the current map center immediately
  /// This is called when user taps "Find Agents Near Me" button
  Future<void> _fetchAgentsAtCurrentLocation() async {
    // Cancel any pending auto-fetch
    _mapMoveDebounce?.cancel();

    if (_currentCenter == null) {
      debugPrint('⚠️ No current center, initializing location');
      await _initLocationAndLoadAgents();
      return;
    }

    debugPrint('🔍 Manual fetch at current map center: $_currentCenter');

    // Fetch immediately at current map center with loading overlay
    await _fetchAgents(_currentCenter!, isAutoFetch: false);
  }

  /// Called when agent markers are positioned and visible
  void _onMarkersReady() {
    if (!mounted) return;
    debugPrint('✅ Markers are ready and visible, hiding glow');
    setState(() {
      _isSearching = false;
    });
  }

  void _showAgentProfile(Agent agent) {
    _closePopup();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgentProfileBottomSheet(agent: agent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomRefreshIndicator(
          onRefresh: _initLocationAndLoadAgents,
          child: Padding(
            padding:
                const EdgeInsets.only(top: kSizedBoxH4, bottom: kSizedBoxH60),
            child: Column(
              children: [
                Padding(
                  padding: kPaddingH16V8,
                  child: SizedBox(
                    height: 48,
                    child: SearchBarWidget(
                      hintText: 'Search by name or property',
                    ),
                  ),
                ),
                QuickSearchTagsWidget(
                  latitude: _currentCenter?.latitude,
                  longitude: _currentCenter?.longitude,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _initialMapCenter == null
                      ? Container() // Empty container while loading
                      : MapScreen(
                          key: _mapKey,
                          controller: _mapController,
                          agents: _agents,
                          onAgentSelected: _onAgentSelected,
                          onMapMoved: _onMapMoved,
                          initialCenter: _initialMapCenter!,
                          onMarkersReady: _onMarkersReady,
                        ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedAgent != null)
          AgentInfoPopup(
            selectedAgent: _selectedAgent!,
            onDismiss: _closePopup,
            popupAnimationController: _popupController,
            closeButtonAnimationController: _closeButtonController,
          ),
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapIconButton(
                icon: Icons.fullscreen,
                onPressed: () {
                  // Navigate to full-screen map page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapFullscreenPage(
                        initialCenter: _currentCenter ?? _initialMapCenter!,
                        initialAgents: _agents,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              _MapIconButton(
                icon: Icons.my_location,
                onPressed: () async {
                  // Center map to user location
                  await _mapController.centerToMyLocation();

                  // Wait for camera to finish moving
                  await Future.delayed(const Duration(milliseconds: 500));

                  // Get current position and fetch agents there
                  try {
                    final pos = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                      timeLimit: const Duration(seconds: 10),
                    );
                    final newCenter = LatLng(pos.latitude, pos.longitude);

                    if (mounted) {
                      _currentCenter = newCenter;
                      await _fetchAgents(newCenter, isAutoFetch: false);
                    }
                  } catch (e) {
                    debugPrint('Error getting location: $e');
                  }
                },
              ),
              const SizedBox(height: 6),
              _MapZoomControls(
                onZoomIn: _mapController.zoomIn,
                onZoomOut: _mapController.zoomOut,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _isFabVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _selectedAgent != null
                ? ViewAgentProfileButton(
                    onPressed: () => _showAgentProfile(_selectedAgent!),
                    isLoading: _isSearching,
                  )
                : AnimatedFloatingActionButton(
                    onPressed: _fetchAgentsAtCurrentLocation,
                    isLoading: _isSearching,
                  ),
          ),
        ),
        if (_initialMapCenter == null)
          const SimpleLoadingOverlay(message: 'Loading map...'),
        if (_isSearching && _initialMapCenter != null)
          const Center(
            child: LocationPulseWidget(
              isVisible: true,
              pulseColor: kPrimaryColor,
              size: 300,
            ),
          ),
      ],
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, color: kPrimaryColor, size: 18),
        ),
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _MapZoomControls({required this.onZoomIn, required this.onZoomOut});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      borderRadius: kRadius20,
      elevation: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: kRadius20Top,
            onTap: onZoomIn,
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.add, color: kPrimaryColor, size: 18),
            ),
          ),
          Container(height: 1, width: 20, color: kGrey400),
          InkWell(
            borderRadius: kRadius20Bottom,
            onTap: onZoomOut,
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.remove, color: kPrimaryColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
