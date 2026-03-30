import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';

/// Service for tracking property metrics (views, inspections, leads)
class PropertyTrackingService {
  final String baseUrl = kBaseUrl;

  /// Increment the view count for a property
  /// Call this when a user opens the property details screen
  Future<Map<String, dynamic>> incrementViewCount(String propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/property/increment-view-count'),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({'property_id': int.tryParse(propertyId) ?? propertyId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw NetworkException(
          'Failed to increment view count',
          NetworkException.fromStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'Error incrementing view count: $e',
        NetworkErrorType.unknown,
      );
    }
  }

  /// Increment the inspection booking count for a property
  /// Call this when a user successfully books an inspection
  Future<Map<String, dynamic>> incrementInspectionBookingCount(
      String propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/property/increment-inspection-booking-count'),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({'property_id': int.tryParse(propertyId) ?? propertyId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw NetworkException(
          'Failed to increment inspection booking count',
          NetworkException.fromStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'Error incrementing inspection booking count: $e',
        NetworkErrorType.unknown,
      );
    }
  }

  /// Increment the leads count for a property
  /// Call this when a user saves a property
  Future<Map<String, dynamic>> incrementLeadsCount(String propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/property/increment-leads-count'),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({'property_id': int.tryParse(propertyId) ?? propertyId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw NetworkException(
          'Failed to increment leads count',
          NetworkException.fromStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'Error incrementing leads count: $e',
        NetworkErrorType.unknown,
      );
    }
  }

  /// Decrement the leads count for a property
  /// Call this when a user unsaves a property
  Future<Map<String, dynamic>> decrementLeadsCount(String propertyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/property/decrement-leads-count'),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({'property_id': int.tryParse(propertyId) ?? propertyId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw NetworkException(
          'Failed to decrement leads count',
          NetworkException.fromStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'Error decrementing leads count: $e',
        NetworkErrorType.unknown,
      );
    }
  }

  /// Get property tracking statistics
  Future<Map<String, dynamic>> getPropertyStats(String propertyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/property/stats?property_id=$propertyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw NetworkException(
          'Failed to get property statistics',
          NetworkException.fromStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'Error getting property statistics: $e',
        NetworkErrorType.unknown,
      );
    }
  }
}
