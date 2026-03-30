import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeoTestScreen extends StatefulWidget {
  const GeoTestScreen({super.key});

  @override
  State<GeoTestScreen> createState() => _GeoTestScreenState();
}

class _GeoTestScreenState extends State<GeoTestScreen> {
  double? _latitude;
  double? _longitude;
  String _message = 'Fetching location...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _message = 'Checking permissions & services...';
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _message = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _message = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _message = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _message = 'Fetching coordinates...';
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint("\n${"=" * 50}");
      debugPrint("🌎 DEVICE LOCATION RETRIEVED 🌎");
      debugPrint("Latitude: ${position.latitude}");
      debugPrint("Longitude: ${position.longitude}");
      debugPrint("${"=" * 50}\n");

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _message = 'Location retrieved successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocation Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                const Icon(
                  Icons.location_on,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Current Position:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_latitude != null && _longitude != null) ...[
                  Text(
                    'Latitude: $_latitude',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Longitude: $_longitude',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ] else
                  const Text(
                    'No Data',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 20),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: (_latitude != null) ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
