import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants.dart';
import 'map_screen.dart';
import 'dart:io' show Platform;

class MapSectionWidget extends StatefulWidget {
  final MapController? controller;
  final List<Map<String, dynamic>> users;
  final Function(Map<String, dynamic> user)? onUserSelected;
  final Function(LatLng)? onMapMoved;
  final LatLng? initialCenter;

  const MapSectionWidget({
    super.key,
    this.controller,
    this.users = const [],
    this.onUserSelected,
    this.onMapMoved,
    this.initialCenter,
  });

  @override
  State<MapSectionWidget> createState() => _MapSectionWidgetState();
}

class _MapSectionWidgetState extends State<MapSectionWidget> {
  LatLng? _currentCenter;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialCenter != null) {
      if (mounted) {
        setState(() {
          _currentCenter = widget.initialCenter;
          _isLoadingLocation = false;
        });
      }
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useDefaultLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // Notify parent about the initial detected location via onMapMoved
        // This is key for screens that need to know the initial center
        widget.onMapMoved?.call(_currentCenter!);
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentCenter = const LatLng(6.5244, 3.3792); // Lagos default
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.3,
        constraints: BoxConstraints(
          minHeight: Platform.isAndroid ? 250.0 : 200.0,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          border: Border.all(color: kGrey400, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    // Calculate height with platform considerations
    final double mapHeight = MediaQuery.of(context).size.height * 0.3;
    final double minHeight =
        Platform.isAndroid ? 250.0 : 200.0; // Increased min height for Android
    final double finalHeight = mapHeight < minHeight ? minHeight : mapHeight;

    return Container(
      height: finalHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: kGrey400, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  MapScreen(
                    controller: widget.controller,
                    users: widget.users,
                    onUserSelected: widget.onUserSelected,
                    onMapMoved: widget.onMapMoved,
                    initialCenter: _currentCenter!,
                  ),

                  // Map Controls (Zoom & Center grouped)
                  if (widget.controller != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMapControlIcon(
                              icon: Icons.add,
                              onPressed: () => widget.controller!.zoomIn(),
                              hasDivider: true,
                            ),
                            _buildMapControlIcon(
                              icon: Icons.remove,
                              onPressed: () => widget.controller!.zoomOut(),
                              hasDivider: true,
                            ),
                            _buildMapControlIcon(
                              icon: Icons.my_location,
                              onPressed: () =>
                                  widget.controller!.centerToMyLocation(),
                              color: kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapControlIcon({
    required IconData icon,
    required VoidCallback onPressed,
    bool hasDivider = false,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color ?? kGrey600,
              size: 20,
            ),
          ),
        ),
        if (hasDivider)
          Container(
            width: 24,
            height: 1,
            color: kGrey200,
          ),
      ],
    );
  }
}
