import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants.dart';
import 'token_storage_service.dart';

/// Service for managing agent inspections
class AgentInspectionService {
  final String baseUrl = kAgentBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Get upcoming inspections count
  Future<int> getUpcomingCount() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        debugPrint('No auth token found');
        return 0;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/inspections/upcoming-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Debug print only on error or specific conditions to avoid spamming console on periodic calls
      if (response.statusCode != 200) {
        debugPrint('Upcoming count response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['upcoming_count'] ?? 0;
        }
      }

      return 0;
    } catch (e) {
      debugPrint('Error fetching upcoming count: $e');
      return 0;
    }
  }

  /// Provides a real-time stream of upcoming inspections count.
  /// Polls the server every [interval].
  Stream<int> getUpcomingInspectionsCountStream({
    Duration interval = const Duration(seconds: 5),
  }) {
    return Stream.periodic(interval).asyncMap((_) => getUpcomingCount());
  }

  /// Get paginated inspections list
  /// [status] can be: 'upcoming', 'completed', 'cancelled', or null for all
  Future<Map<String, dynamic>> getInspections({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      String url = '$baseUrl/inspections?page=$page&per_page=$perPage';
      if (status != null) {
        url += '&status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Inspections response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch inspections',
        };
      }
    } catch (e) {
      debugPrint('Error fetching inspections: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get inspection details by ID
  Future<Map<String, dynamic>> getInspectionDetails(int inspectionId) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/inspections/$inspectionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Inspection details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Inspection not found',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch inspection details',
        };
      }
    } catch (e) {
      debugPrint('Error fetching inspection details: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Update inspection status
  /// [status] can be: 'scheduled', 'confirmed', 'completed', 'cancelled'
  Future<Map<String, dynamic>> updateInspectionStatus(
    int inspectionId,
    String status,
  ) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/inspections/$inspectionId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      debugPrint('Update status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Inspection not found',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['message'] ?? 'Failed to update inspection status',
        };
      }
    } catch (e) {
      debugPrint('Error updating inspection status: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Reschedule an inspection
  /// [inspectionDate] format: 'YYYY-MM-DD'
  /// [inspectionTime] format: 'HH:mm:ss'
  Future<Map<String, dynamic>> rescheduleInspection(
    int inspectionId,
    String inspectionDate,
    String inspectionTime,
  ) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No auth token found',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/inspections/$inspectionId/reschedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inspection_date': inspectionDate,
          'inspection_time': inspectionTime,
        }),
      );

      debugPrint('Reschedule response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Inspection not found',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to reschedule inspection',
        };
      }
    } catch (e) {
      debugPrint('Error rescheduling inspection: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
