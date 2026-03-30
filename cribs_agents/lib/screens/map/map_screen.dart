import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants.dart';
import 'user_marker.dart';

class MapScreen extends StatefulWidget {
  final MapController? controller;
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic> user)? onUserSelected;
  final Function(LatLng)? onMapMoved;
  final LatLng initialCenter;

  const MapScreen({
    super.key,
    this.controller,
    this.users = const [],
    this.onUserSelected,
    this.onMapMoved,
    required this.initialCenter,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class MapController {
  _MapScreenState? _state;

  void _attach(_MapScreenState s) => _state = s;
  void _detach() => _state = null;

  void setUsersVisibility(bool visible) => _state?._setUsersVisibility(visible);
  void updateUserPositions() => _state?._updateUserPositions();
  Future<void> centerToMyLocation() async =>
      await _state?._centerToMyLocation();
  void centerOnPosition(LatLng pos, double zoom) =>
      _state?._centerOnPosition(pos, zoom);
  void zoomIn() => _state?._zoomIn();
  void zoomOut() => _state?._zoomOut();
  void refreshUsersFully() => _state?._refreshUsersFully();
  void fitToUsers() => _state?._zoomToFitUsers();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final GlobalKey<UserMarkerState> _userMarkerKey =
      GlobalKey<UserMarkerState>();
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
    if (oldWidget.users != widget.users) {
      final usersChanged = !_areUserListsEqual(oldWidget.users, widget.users);

      if (usersChanged) {
        debugPrint(
            '📦 Users changed: ${oldWidget.users.length} -> ${widget.users.length}');
        _userMarkerKey.currentState?.setUsers(widget.users);

        // If we already did initial setup, just update positions
        if (_mapReady && _initialSetupDone && !_isCameraMoving) {
          _scheduleMarkerUpdate();
        }
      }
    }
  }

  bool _areUserListsEqual(
      List<Map<String, dynamic>> oldList, List<Map<String, dynamic>> newList) {
    if (oldList.length != newList.length) return false;
    final oldIds = oldList.map((u) => u['id']?.toString() ?? '').toSet();
    final newIds = newList.map((u) => u['id']?.toString() ?? '').toSet();
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
    _idleDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _mapController != null) {
        _updateUserPositions();
      }
    });
  }

  void _refreshUsersFully() {
    if (!mounted || _mapController == null) return;

    debugPrint('🔄 Refreshing users fully');
    _userMarkerKey.currentState?.setUsers(widget.users);

    // Force visibility and update
    _setUsersVisibility(true);
    _scheduleMarkerUpdate();
  }

  Future<void> _performInitialSetup() async {
    if (!mounted || _initialSetupDone || _mapController == null) return;
    if (widget.users.isEmpty) return;

    debugPrint('🎬 Performing initial setup with ${widget.users.length} users');
    _initialSetupDone = true;

    try {
      await _zoomToFitUsers();
      await Future.delayed(
          Duration(milliseconds: Platform.isAndroid ? 700 : 600));

      if (!mounted) return;

      await _userMarkerKey.currentState?.updatePositions(_mapController!);
      _setUsersVisibility(true);

      // Set initial center for notifications
      if (_latestCameraPosition != null) {
        _lastNotifiedCenter = _latestCameraPosition!.target;
      }

      debugPrint('✅ Initial setup complete');
    } catch (e) {
      debugPrint('❌ Initial setup error: $e');
      _initialSetupDone = false;
    }
  }

  Future<void> _updateUserPositions() async {
    if (!mounted || _mapController == null || _isCameraMoving) return;

    _updateCounter++;
    final currentUpdate = _updateCounter;

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted || currentUpdate != _updateCounter) return;

    await _userMarkerKey.currentState?.updatePositionsSmooth(_mapController!);
  }

  void _setUsersVisibility(bool visible) {
    _userMarkerKey.currentState?.setVisibility(visible);
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
          timeLimit: Duration(seconds: 10),
        ),
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

  Future<void> _zoomToFitUsers() async {
    final controller = _mapController;
    if (controller == null || widget.users.isEmpty) return;

    try {
      if (widget.users.length == 1) {
        final user = widget.users.first;
        final lat = user['lat'];
        final lng = user['lon'];
        if (lat != null && lng != null) {
          final latDouble =
              (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
          final lngDouble =
              (lng is num) ? lng.toDouble() : double.tryParse(lng.toString());

          if (latDouble != null && lngDouble != null) {
            final zoomLevel = Platform.isAndroid
                ? kFixedZoomLevelAndroid
                : kFixedZoomLevelIOS;
            await controller.animateCamera(CameraUpdate.newLatLngZoom(
                LatLng(latDouble, lngDouble), zoomLevel));
          }
        }
      } else {
        final bounds = _calculateBounds(widget.users);
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

  LatLngBounds? _calculateBounds(List<Map<String, dynamic>> users) {
    final validPoints = <LatLng>[];

    for (final user in users) {
      final lat = user['lat'];
      final lon = user['lon'];

      if (lat != null && lon != null) {
        final latDouble =
            (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
        final lonDouble =
            (lon is num) ? lon.toDouble() : double.tryParse(lon.toString());

        if (latDouble != null && lonDouble != null) {
          validPoints.add(LatLng(latDouble, lonDouble));
        }
      }
    }

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
    _userMarkerKey.currentState?.setUsers(widget.users);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_initialSetupDone && widget.users.isNotEmpty) {
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

    if (!_initialSetupDone && _mapReady && widget.users.isNotEmpty) {
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
        UserMarker(
          key: _userMarkerKey,
          users: widget.users,
          visible: _initialSetupDone,
          mapController: _mapController,
          onSelected: widget.onUserSelected,
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
