import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapService {
  /// Fetch all users with location data
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$kAgentBaseUrl/map/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> users = data['users'] ?? [];
          return users.cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch users');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Fetch nearby users within a specific radius
  Future<List<Map<String, dynamic>>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radius = 10.0, // radius in kilometers
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$kAgentBaseUrl/map/users/nearby'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        }),
      );

      if (kDebugMode) {
        debugPrint(
            'MAP_SERVICE: Nearby Users Response: ${response.statusCode} | ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> users = data['users'] ?? [];
          if (kDebugMode) {
            debugPrint('MAP_SERVICE: Parsed ${users.length} users');
          }
          return users.cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch nearby users');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching nearby users: $e');
      throw Exception('Failed to fetch nearby users: $e');
    }
  }
}
