import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';
import 'token_storage_service.dart';

/// Service for managing agent active areas with Google Places autocomplete
class ActiveAreasService {
  final String baseUrl = kBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  // Google Places API key (same as used for Google Maps)
  static const String _googleApiKey = 'AIzaSyC4xgutAJjv9z8vw4ZHRsqx2pvvMQxa_oE';
  static const String _placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  /// Get autocomplete suggestions for an area name
  /// Uses Google Places Autocomplete API
  Future<List<PlaceSuggestion>> getPlaceSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      final uri = Uri.parse('$_placesBaseUrl/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&types=(regions)'
          '&components=country:ng' // Restrict to Nigeria
          '&key=$_googleApiKey');

      debugPrint('Fetching place suggestions for: $query');
      debugPrint('Request URL: $uri');

      final response = await http.get(uri);

      debugPrint('Places API response status: ${response.statusCode}');
      debugPrint('Places API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          debugPrint('Found ${predictions.length} suggestions');
          return predictions.map((p) => PlaceSuggestion.fromJson(p)).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          debugPrint('No results found for query: $query');
          return [];
        } else {
          // Log the specific error
          debugPrint('Places API error status: ${data['status']}');
          debugPrint(
              'Places API error message: ${data['error_message'] ?? 'No error message'}');
          return [];
        }
      } else {
        debugPrint('Places API HTTP error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching place suggestions: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get the current active areas for the logged-in agent
  Future<Map<String, dynamic>> getActiveAreas() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/agent/profile/information'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Get active areas response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final agentInfo = responseData['data']?['agent_information'];

        // Extract active_areas from agent_information (stored as JSON string)
        List<String> activeAreas = [];
        if (agentInfo?['active_areas'] != null) {
          final areasData = agentInfo['active_areas'];
          if (areasData is String) {
            // Parse JSON string
            try {
              final parsed = jsonDecode(areasData);
              if (parsed is List) {
                activeAreas = parsed.map((e) => e.toString()).toList();
              }
            } catch (e) {
              debugPrint('Error parsing active_areas JSON: $e');
            }
          } else if (areasData is List) {
            activeAreas = areasData.map((e) => e.toString()).toList();
          }
        }

        return {
          'success': true,
          'active_areas': activeAreas,
          'data': agentInfo,
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch active areas',
        };
      }
    } catch (e) {
      debugPrint('Error fetching active areas: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Set the active areas for the logged-in agent
  /// Updates the active_areas column in agent_information table
  Future<Map<String, dynamic>> setActiveAreas(List<String> activeAreas) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final uri = Uri.parse('$baseUrl/agent/profile/update');

      // Use regular POST with JSON body for arrays
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'active_areas': activeAreas,
        }),
      );

      debugPrint('Setting active areas: $activeAreas');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Active areas updated successfully',
          'active_areas': activeAreas,
          'data': responseData,
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update active areas',
        };
      }
    } catch (e) {
      debugPrint('Error setting active areas: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Update the agent's current location (latitude and longitude)
  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final uri = Uri.parse('$baseUrl/agent/profile/location');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      debugPrint('Updating agent location: $lat, $lng');
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Location updated successfully',
          'data': responseData,
        };
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update location',
        };
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}

/// Model class for place suggestions from Google Places API
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
    );
  }

  @override
  String toString() => description;
}
