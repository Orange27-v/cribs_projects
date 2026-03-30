import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cribs_agents/services/location_service.dart';
import 'package:cribs_agents/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  bool _isSaving = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Location services are disabled.');
        }
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            SnackbarHelper.showError(
                context, 'Location permissions are denied');
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          SnackbarHelper.showError(
              context, 'Location permissions are permanently denied');
        }
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _selectedPosition = _currentPosition;
        _isLoading = false;
      });

      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error fetching location: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedPosition == null) return;

    setState(() => _isSaving = true);
    try {
      await _locationService.updateLocation(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
      );
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Location updated successfully',
            position: FlashPosition.bottom);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to update location: $e',
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('Location Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_currentPosition != null)
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (position) {
                      setState(() => _selectedPosition = position);
                    },
                    markers: {
                      if (_selectedPosition != null)
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: _selectedPosition!,
                          draggable: true,
                          onDragEnd: (newPosition) {
                            setState(() => _selectedPosition = newPosition);
                          },
                        ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  )
                else
                  const Center(
                      child: Text('Unable to load map. Check permissions.')),

                // Overlay instructions
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kWhite.withValues(alpha: 0.9),
                      borderRadius: kRadius12,
                      boxShadow: [
                        BoxShadow(
                          color: kBlack.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Tap on the map or drag the marker to your current business location.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 12, color: kBlack87),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedPosition != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, Lon: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kBlack87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                PrimaryButton(
                  text: _isSaving ? 'Saving...' : 'Save Current Location',
                  onPressed: _isSaving || _selectedPosition == null
                      ? null
                      : _saveLocation,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
