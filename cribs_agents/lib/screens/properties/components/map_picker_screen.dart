import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cribs_agents/constants.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _initialPosition = LatLng(6.5244, 3.3792); // Lagos

  LatLng _selectedPosition = _initialPosition;

  void _onTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Property Location',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: kPrimaryColor),
            onPressed: () {
              Navigator.of(context).pop(_selectedPosition);
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _initialPosition,
          zoom: 12.0,
        ),
        onTap: _onTap,
        markers: {
          Marker(
            markerId: const MarkerId('selected-location'),
            position: _selectedPosition,
            infoWindow: InfoWindow(
              title: 'Selected Location',
              snippet:
                  '${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}',
            ),
            icon: BitmapDescriptor.defaultMarker,
          ),
        },
      ),
    );
  }
}
