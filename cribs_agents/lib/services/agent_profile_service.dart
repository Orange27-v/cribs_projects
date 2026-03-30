import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'token_storage_service.dart';

/// Service for managing agent profile information
class AgentProfileService {
  final String baseUrl = kBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Update agent profile information
  Future<Map<String, dynamic>> updateAgentProfile({
    required String bio,
    String? gender,
    required bool isLicensed,
    required int experienceYears,
    required double bookingFees,
    File? profileImage,
  }) async {
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

      // Add fields
      request.fields['bio'] = bio;
      if (gender != null) {
        request.fields['gender'] = gender;
      }
      request.fields['is_licensed'] = isLicensed ? '1' : '0';
      request.fields['experience_years'] = experienceYears.toString();
      request.fields['booking_fees'] = bookingFees.toString();

      // Add profile image if provided
      if (profileImage != null) {
        final mimeType = lookupMimeType(profileImage.path);
        final multipartFile = await http.MultipartFile.fromPath(
          'profile_picture',
          profileImage.path,
          contentType: mimeType != null
              ? MediaType.parse(mimeType)
              : MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      debugPrint('Updating agent profile...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
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
          'message': errorData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      debugPrint('Error updating agent profile: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Get agent profile information
  Future<Map<String, dynamic>> getAgentProfile() async {
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

      debugPrint('Get agent profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
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
          'message': errorData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      debugPrint('Error fetching agent profile: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
