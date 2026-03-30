import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../constants.dart';
import 'agent_marker.dart';
import 'package:cribs_arena/models/agent.dart';

class MapScreen extends StatefulWidget {
  final MapController? controller;
  final List<Agent> agents;
  final Function(Agent agent)? onAgentSelected;
  final Function(LatLng)? onMapMoved;
  final LatLng initialCenter;
  final VoidCallback? onMarkersReady;

  const MapScreen({
    super.key,
    this.controller,
    this.agents = const [],
    this.onAgentSelected,
    this.onMapMoved,
    required this.initialCenter,
    this.onMarkersReady,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class MapController {
  _MapScreenState? _state;

  void _attach(_MapScreenState s) => _state = s;
  void _detach() => _state = null;

  void setAgentsVisibility(bool visible) =>
      _state?._setAgentsVisibility(visible);
  void updateAgentPositions() => _state?._updateAgentPositions();
  Future<void> centerToMyLocation() async =>
      await _state?._centerToMyLocation();
  void centerOnPosition(LatLng pos, double zoom) =>
      _state?._centerOnPosition(pos, zoom);
  void zoomIn() => _state?._zoomIn();
  void zoomOut() => _state?._zoomOut();
  void refreshAgentsFully() => _state?._refreshAgentsFully();
  void fitToAgents() => _state?._zoomToFitAgents();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final GlobalKey<AgentMarkerState> _agentMarkerKey =
      GlobalKey<AgentMarkerState>();
  bool _mapReady = false;
  bool _initialSetupDone = false;
  Timer? _idleDebounceTimer;
  Timer? _notifyDebounceTimer;
  LatLng? _lastNotifiedCenter;
  static const double _minNotifyDistanceMeters = 500;
  CameraPosition? _latestCameraPosition;
  bool _isCameraMoving = false;
  int _updateCounter = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agents != widget.agents) {
      final agentsChanged =
          !_areAgentListsEqual(oldWidget.agents, widget.agents);

      if (agentsChanged) {
        debugPrint(
            '📦 Agents changed: ${oldWidget.agents.length} -> ${widget.agents.length}');
        _agentMarkerKey.currentState?.setAgents(widget.agents);

        // If we already did initial setup, just update positions
        if (_mapReady && _initialSetupDone && !_isCameraMoving) {
          _scheduleMarkerUpdate();
        }
      }
    }
  }

  bool _areAgentListsEqual(List<Agent> oldList, List<Agent> newList) {
    if (oldList.length != newList.length) return false;
    final oldIds = oldList.map((a) => a.id).toSet();
    final newIds = newList.map((a) => a.id).toSet();
    return oldIds.containsAll(newIds) && newIds.containsAll(oldIds);
  }

  @override
  void dispose() {
    _idleDebounceTimer?.cancel();
    _notifyDebounceTimer?.cancel();
    widget.controller?._detach();
    _mapController?.dispose();
    super.dispose();
  }

  void _scheduleMarkerUpdate() {
    _idleDebounceTimer?.cancel();
    _idleDebounceTimer = Timer(const Duration(milliseconds: 150), () async {
      if (mounted && _mapController != null) {
        await _updateAgentPositions();
        if (mounted) {
          widget.onMarkersReady?.call();
        }
      }
    });
  }

  void _refreshAgentsFully() {
    if (!mounted || _mapController == null) return;

    debugPrint('🔄 Refreshing agents fully');
    _agentMarkerKey.currentState?.setAgents(widget.agents);

    // Force visibility and update
    _setAgentsVisibility(true);
    _scheduleMarkerUpdate();
  }

  Future<void> _performInitialSetup() async {
    if (!mounted || _initialSetupDone || _mapController == null) return;
    if (widget.agents.isEmpty) return;

    debugPrint(
        '🎬 Performing initial setup with ${widget.agents.length} agents');
    _initialSetupDone = true;

    try {
      await _zoomToFitAgents();
      await Future.delayed(
          Duration(milliseconds: Platform.isAndroid ? 700 : 600));

      if (!mounted) return;

      await _agentMarkerKey.currentState?.updatePositions(_mapController!);
      _setAgentsVisibility(true);

      // Set initial center for notifications
      if (_latestCameraPosition != null) {
        _lastNotifiedCenter = _latestCameraPosition!.target;
      }

      debugPrint('✅ Initial setup complete');

      // Notify parent that markers are ready and visible
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        widget.onMarkersReady?.call();
      }
    } catch (e) {
      debugPrint('❌ Initial setup error: $e');
      _initialSetupDone = false;
    }
  }

  Future<void> _updateAgentPositions() async {
    if (!mounted || _mapController == null || _isCameraMoving) return;

    _updateCounter++;
    final currentUpdate = _updateCounter;

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted || currentUpdate != _updateCounter) return;

    await _agentMarkerKey.currentState?.updatePositionsSmooth(_mapController!);
  }

  void _setAgentsVisibility(bool visible) {
    _agentMarkerKey.currentState?.setVisibility(visible);
  }

  Future<void> _centerToMyLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('⚠️ Location services disabled');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      debugPrint('📍 Centering to location: ${pos.latitude}, ${pos.longitude}');

      await controller.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
    } catch (e) {
      debugPrint('❌ Center error: $e');
    }
  }

  Future<void> _centerOnPosition(LatLng position, double zoom) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
  }

  Future<void> _zoomIn() async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _zoomToFitAgents() async {
    final controller = _mapController;
    if (controller == null || widget.agents.isEmpty) return;

    try {
      if (widget.agents.length == 1) {
        final agent = widget.agents.first;
        final lat = agent.latitude;
        final lng = agent.longitude;
        if (lat != null && lng != null) {
          final zoomLevel =
              Platform.isAndroid ? kFixedZoomLevelAndroid : kFixedZoomLevelIOS;
          await controller.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoomLevel));
        }
      } else {
        final bounds = _calculateBounds(widget.agents);
        if (bounds != null) {
          final padding =
              Platform.isAndroid ? kAndroidMapPadding : kIOSMapPadding;
          await controller
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
        }
      }
    } catch (e) {
      debugPrint('ZoomToFit error: $e');
    }
  }

  LatLngBounds? _calculateBounds(List<Agent> agents) {
    final validPoints = agents
        .where((a) => a.latitude != null && a.longitude != null)
        .map((a) => LatLng(a.latitude!, a.longitude!))
        .toList();

    if (validPoints.isEmpty) return null;

    double minLat = validPoints.first.latitude;
    double maxLat = validPoints.first.latitude;
    double minLng = validPoints.first.longitude;
    double maxLng = validPoints.first.longitude;

    for (final point in validPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapReady = true;
    _agentMarkerKey.currentState?.setAgents(widget.agents);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_initialSetupDone && widget.agents.isNotEmpty) {
        _performInitialSetup();
      }
    });
  }

  void _onCameraMove(CameraPosition pos) {
    _latestCameraPosition = pos;
    _isCameraMoving = true;

    _idleDebounceTimer?.cancel();
  }

  void _onCameraIdle() async {
    _isCameraMoving = false;

    if (!_initialSetupDone && _mapReady && widget.agents.isNotEmpty) {
      _performInitialSetup();
      return;
    }

    // Update marker positions after camera stops
    _scheduleMarkerUpdate();

    // Debounce parent notification
    _notifyDebounceTimer?.cancel();
    _notifyDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final camPos = _latestCameraPosition;
      if (camPos != null && mounted) {
        final center = camPos.target;
        if (_shouldNotify(center)) {
          final distance = _getDistanceFromLast(center);
          debugPrint(
              '🗺️ Map moved ${distance.toStringAsFixed(0)}m - notifying parent');
          _lastNotifiedCenter = center;
          widget.onMapMoved?.call(center);
        }
      }
    });
  }

  bool _shouldNotify(LatLng center) {
    final last = _lastNotifiedCenter;
    if (last == null) return true;

    final distance = _getDistanceFromLast(center);
    return distance >= _minNotifyDistanceMeters;
  }

  double _getDistanceFromLast(LatLng center) {
    final last = _lastNotifiedCenter;
    if (last == null) return double.infinity;

    return Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      center.latitude,
      center.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
          initialCameraPosition: CameraPosition(
            target: widget.initialCenter,
            zoom: Platform.isAndroid
                ? kInitialMapZoomAndroid
                : kInitialMapZoomIOS,
          ),
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
          compassEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
        AgentMarker(
          key: _agentMarkerKey,
          agents: widget.agents,
          visible: _initialSetupDone,
          mapController: _mapController,
          onSelected: widget.onAgentSelected,
        ),
        const IgnorePointer(
          child: Center(
            child: Icon(Icons.location_pin, color: kPrimaryColor, size: 50),
          ),
        ),
      ],
    );
  }
}
