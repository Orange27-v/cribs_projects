import 'dart:async';
import 'package:cribs_arena/screens/map/map_screen.dart';
import 'package:cribs_arena/screens/schedule/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants.dart';
import '../../services/api_service.dart';
import '../agents/agent_info_popup.dart';
import '../agents/agent_profile_bottom_sheet.dart';
import '../components/app_header_content.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/models/agent.dart';
import '../user/user_widgets/glow_loading_widget.dart';

/// Full-screen map page with distraction-free view
/// Includes app header and agent discovery actions
class MapFullscreenPage extends StatefulWidget {
  final LatLng initialCenter;
  final List<Agent> initialAgents;

  const MapFullscreenPage({
    super.key,
    required this.initialCenter,
    required this.initialAgents,
  });

  @override
  State<MapFullscreenPage> createState() => _MapFullscreenPageState();
}

class _MapFullscreenPageState extends State<MapFullscreenPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();

  late List<Agent> _agents;
  Agent? _selectedAgent;
  late LatLng _currentCenter;

  bool _isFabVisible = true;
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
    _agents = widget.initialAgents;
    _currentCenter = widget.initialCenter;

    _popupController =
        AnimationController(vsync: this, duration: kDuration300ms);
    _closeButtonController =
        AnimationController(vsync: this, duration: kDuration150ms);
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
    _currentCenter = center;

    // Debounce automatic fetching
    _mapMoveDebounce?.cancel();
    _mapMoveDebounce = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('🗺️ Auto-fetching agents after 5s idle at: $center');
        _fetchAgents(center, isAutoFetch: true);
      }
    });
  }

  Future<void> _fetchAgents(LatLng center, {required bool isAutoFetch}) async {
    if (!mounted || _isFetchingAgents) return;

    _isFetchingAgents = true;

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
          setState(() {});
        }
      }

      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        _mapController.refreshAgentsFully();
      }

      // Note: _isSearching will be set to false by _onMarkersReady callback
      // This ensures the loading overlay stays visible until markers are actually positioned
    } catch (e) {
      debugPrint('❌ Error loading agents: $e');
      if (mounted) {
        // Only clear agents if this was a manual search initiated by the user
        if (!isAutoFetch) {
          setState(() {
            _agents = [];
            _isSearching = false;
          });
        } else {
          // For auto-fetch, just stop the spinner/searching state but keep existing agents
          setState(() {
            _isSearching = false;
          });
        }
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

  bool _agentsChanged(List<Agent> newAgents) {
    if (_agents.length != newAgents.length) return true;

    final oldIds = _agents.map((a) => a.id).toSet();
    final newIds = newAgents.map((a) => a.id).toSet();

    return !oldIds.containsAll(newIds) || !newIds.containsAll(oldIds);
  }

  Future<void> _fetchAgentsAtCurrentLocation() async {
    _mapMoveDebounce?.cancel();

    debugPrint('🔍 Manual fetch at current map center: $_currentCenter');
    await _fetchAgents(_currentCenter, isAutoFetch: false);
  }

  /// Called when agent markers are positioned and visible
  void _onMarkersReady() {
    if (!mounted) return;
    debugPrint('✅ Markers are ready and visible, hiding loading overlay');
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
    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // App Header
                AppHeaderContent(
                  horizontalPadding: 12.0,
                  verticalPadding: 8.0,
                  onNotificationPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                  onCalendarPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyScheduleScreen(),
                      ),
                    );
                  },
                ),

                // Full-screen Map
                Expanded(
                  child: MapScreen(
                    key: _mapKey,
                    controller: _mapController,
                    agents: _agents,
                    onAgentSelected: _onAgentSelected,
                    onMapMoved: _onMapMoved,
                    initialCenter: widget.initialCenter,
                    onMarkersReady: _onMarkersReady,
                  ),
                ),
              ],
            ),

            // Agent Info Popup
            if (_selectedAgent != null)
              AgentInfoPopup(
                selectedAgent: _selectedAgent!,
                onDismiss: _closePopup,
                popupAnimationController: _popupController,
                closeButtonAnimationController: _closeButtonController,
              ),

            // Map Controls
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Exit Full-Screen Button
                  _MapIconButton(
                    icon: Icons.fullscreen_exit,
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(height: 6),

                  // My Location Button
                  _MapIconButton(
                    icon: Icons.my_location,
                    onPressed: () async {
                      await _mapController.centerToMyLocation();
                      await Future.delayed(const Duration(milliseconds: 500));

                      try {
                        final pos = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(
                            accuracy: LocationAccuracy.high,
                          ),
                        ).timeout(const Duration(seconds: 10));
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
                  SizedBox(height: 6),

                  // Zoom Controls
                  _MapZoomControls(
                    onZoomIn: _mapController.zoomIn,
                    onZoomOut: _mapController.zoomOut,
                  ),
                ],
              ),
            ),

            // Find Agents Button
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
            SizedBox(height: 4),
            // Loading Overlay
            if (_isSearching)
              Center(
                child: LocationPulseWidget(
                  isVisible: _isSearching,
                  pulseColor: kPrimaryColor,
                  size: 300,
                ),
              ),
          ],
        ),
      ),
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
