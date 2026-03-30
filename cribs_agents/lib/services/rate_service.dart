import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';
import 'token_storage_service.dart';

/// Service for managing agent booking rate/fees
class RateService {
  final String baseUrl = kBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Get the current booking fees for the logged-in agent
  Future<Map<String, dynamic>> getBookingFees() async {
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

      debugPrint('Get booking fees response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final agentInfo = responseData['data']?['agent_information'];

        // Extract booking_fees from agent_information
        final bookingFees = agentInfo?['booking_fees'];

        return {
          'success': true,
          'booking_fees': bookingFees != null
              ? double.tryParse(bookingFees.toString()) ?? 0.0
              : 0.0,
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
          'message': errorData['message'] ?? 'Failed to fetch booking fees',
        };
      }
    } catch (e) {
      debugPrint('Error fetching booking fees: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Set the booking fees for the logged-in agent
  /// Updates the booking_fees column in agent_information table
  Future<Map<String, dynamic>> setBookingFees(double bookingFees) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please log in again.',
        };
      }

      final uri = Uri.parse('$baseUrl/agent/profile/update');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add booking_fees field
      request.fields['booking_fees'] = bookingFees.toString();

      debugPrint('Setting booking fees to: $bookingFees');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        final agentInfo = responseData['data']?['agent_information'];
        final updatedFees = agentInfo?['booking_fees'];

        return {
          'success': true,
          'message': 'Booking fees updated successfully',
          'booking_fees': updatedFees != null
              ? double.tryParse(updatedFees.toString()) ?? bookingFees
              : bookingFees,
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
          'message': errorData['message'] ?? 'Failed to update booking fees',
        };
      }
    } catch (e) {
      debugPrint('Error setting booking fees: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
