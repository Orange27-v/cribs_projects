import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class FetchNearbyAgentsService {
  final String baseUrl = kBaseUrl;
  final AuthService _authService = AuthService();

  Future<List<Agent>> getNearbyAgents({double radius = 50.0}) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please log in again.');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable location services.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
              'Location permissions are denied. Please grant location permission.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable them in app settings.');
      }

      // Get current position with timeout
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Location request timed out. Please try again.');
          },
        );
      } catch (e) {
        if (e.toString().contains('timeout') ||
            e.toString().contains('timed out')) {
          rethrow;
        }
        throw Exception('Failed to get current location: ${e.toString()}');
      }

      // Make HTTP request with timeout
      final uri = Uri.parse(
          '$baseUrl/agents/nearby?lat=${position.latitude}&lon=${position.longitude}&radius=$radius');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Request timed out. Please check your internet connection.');
        },
      );

      // Handle different response status codes
      if (response.statusCode == 200) {
        try {
          if (response.body.isEmpty) {
            debugPrint('Empty response body from nearby agents API');
            return [];
          }

          final data = jsonDecode(response.body);

          // Safely parse the response
          if (data == null) {
            debugPrint('Null response data from nearby agents API');
            return [];
          }

          // Handle different response structures
          List<dynamic> agentsList;
          if (data is Map<String, dynamic>) {
            if (data.containsKey('data') && data['data'] is Map) {
              final dataObj = data['data'] as Map<String, dynamic>;
              if (dataObj.containsKey('agents') && dataObj['agents'] is List) {
                agentsList = dataObj['agents'] as List;
              } else if (data.containsKey('agents') && data['agents'] is List) {
                agentsList = data['agents'] as List;
              } else {
                debugPrint('Unexpected response structure: $data');
                return [];
              }
            } else if (data.containsKey('agents') && data['agents'] is List) {
              agentsList = data['agents'] as List;
            } else {
              debugPrint('Unexpected response structure: $data');
              return [];
            }
          } else if (data is List) {
            agentsList = data;
          } else {
            debugPrint('Unexpected response type: ${data.runtimeType}');
            return [];
          }

          // Safely map agents, filtering out any null/invalid entries
          final agents = agentsList
              .where((agent) => agent != null && agent is Map)
              .map((agent) {
                try {
                  return Agent.fromJson(agent as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing agent: $e, data: $agent');
                  return null;
                }
              })
              .whereType<Agent>()
              .toList();

          return agents;
        } catch (e) {
          debugPrint('Error parsing response: $e, body: ${response.body}');
          throw Exception(
              'Failed to parse nearby agents data. Please try again.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Access denied. You don\'t have permission to access this resource.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(
            'Failed to load nearby agents. Status: ${response.statusCode}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in getNearbyAgents: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }
}
