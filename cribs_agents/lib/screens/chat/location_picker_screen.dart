import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:latlong2/latlong.dart' as latlong;

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  LatLng?
      _currentPosition; // Changed to nullable - will be set when location is fetched
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationError(
              'Location services are disabled. Please enable them.');
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showLocationError('Location permission denied.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationError(
              'Location permission permanently denied. Please enable in settings.');
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _pickedLocation = _currentPosition;
          _isLoading = false;
        });

        // Animate camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showLocationError('Failed to get current location: ${e.toString()}');
      }
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _isLoading = true);
            _getCurrentLocation();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // Convert to latlong.LatLng for consistency with conversation.dart
                final location = latlong.LatLng(
                  _pickedLocation!.latitude,
                  _pickedLocation!.longitude,
                );
                Navigator.pop(context, location);
              },
              tooltip: 'Confirm location',
            ),
        ],
      ),
      body: _currentPosition == null
          ? Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CustomLoadingIndicator(
                  color: kPrimaryColor,
                ),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Set initial picked location to current position
                    if (_pickedLocation == null && _currentPosition != null) {
                      setState(() {
                        _pickedLocation = _currentPosition;
                      });
                    }
                  },
                  onTap: (position) {
                    setState(() {
                      _pickedLocation = position;
                    });
                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Location selected: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: kPrimaryColor,
                      ),
                    );
                  },
                  onCameraMove: (position) {
                    // Update picked location to map center when dragging
                    if (mounted) {
                      setState(() {
                        _pickedLocation = position.target;
                      });
                    }
                  },
                  markers: _pickedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: _pickedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                            infoWindow: InfoWindow(
                              title: 'Selected Location',
                              snippet:
                                  '${_pickedLocation!.latitude.toStringAsFixed(6)}, ${_pickedLocation!.longitude.toStringAsFixed(6)}',
                            ),
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                // Center crosshair
                if (!_isLoading)
                  Center(
                    child: Icon(
                      Icons.add,
                      size: 40,
                      color: kPrimaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CustomLoadingIndicator(
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                // Send Location Button
                if (_pickedLocation != null && !_isLoading)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: PrimaryButton(
                      text: 'Send Location',
                      icon: const Icon(Icons.send, color: kWhite, size: 20),
                      onPressed: () {
                        // Convert to latlong.LatLng for consistency
                        final location = latlong.LatLng(
                          _pickedLocation!.latitude,
                          _pickedLocation!.longitude,
                        );
                        Navigator.pop(context, location);
                      },
                    ),
                  ),
                // Instructions
                if (!_isLoading)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: kPaddingAll12,
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: kPrimaryColor, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap on the map to select a location',
                              style: TextStyle(
                                fontSize: 14,
                                color: kBlack87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Map Controls (Center + Zoom)
                if (!_isLoading)
                  Positioned(
                    bottom: _pickedLocation != null ? 100 : 30,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Center to My Location Button
                        Material(
                          color: kWhite,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () async {
                              if (_currentPosition != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      _currentPosition!, 15),
                                );
                              } else {
                                // Retry getting location
                                setState(() => _isLoading = true);
                                await _getCurrentLocation();
                              }
                            },
                            child: const Padding(
                              padding: kPaddingAll5,
                              child: Icon(
                                Icons.my_location,
                                color: kPrimaryColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Zoom Controls
                        Material(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(20),
                          elevation: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                onTap: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.zoomIn(),
                                  );
                                },
                                child: const Padding(
                                  padding: kPaddingAll5,
                                  child: Icon(
                                    Icons.add,
                                    color: kPrimaryColor,
                                    size: 18,
                                  ),
                                ),
                              ),
                              Container(
                                height: 1,
                                width: 20,
                                color: kGrey400,
                              ),
                              InkWell(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(20),
                                ),
                                onTap: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.zoomOut(),
                                  );
                                },
                                child: const Padding(
                                  padding: kPaddingAll5,
                                  child: Icon(
                                    Icons.remove,
                                    color: kPrimaryColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
