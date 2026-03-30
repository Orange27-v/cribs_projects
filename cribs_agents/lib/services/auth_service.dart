import 'dart:convert';
import 'dart:io';
import 'package:cribs_agents/services/socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';

import 'token_storage_service.dart';
import 'firebase_messaging_service.dart';

/// Core authentication service for agent login, registration, and profile management
class AuthService {
  final String baseUrl = kBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  // Expose token storage methods for backward compatibility
  Future<String?> getToken() => _tokenStorage.getToken();
  Future<void> clearToken() => _tokenStorage.clearToken();
  Future<bool> isLoggedIn() => _tokenStorage.isLoggedIn();

  /// Register a new agent account
  Future<http.Response> register({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String area,
    required String role,
    required double latitude,
    required double longitude,
    required String password,
    String? fcmToken,
    String? platform,
  }) async {
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'password': password,
    };

    if (fcmToken != null) {
      body['fcm_token'] = fcmToken;
    }

    if (platform != null) {
      body['platform'] = platform;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/agent/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String? token = responseData['token'];
      if (token != null) {
        await _tokenStorage.saveToken(token);
      } else {
        debugPrint(
            'Registration successful, but no token received from backend.');
      }
    }
    return response;
  }

  /// Login with email and password
  Future<http.Response> login({
    required String email,
    required String password,
    String? fcmToken,
    String? platform,
  }) async {
    final body = {
      'email': email,
      'password': password,
    };

    if (fcmToken != null) {
      body['fcm_token'] = fcmToken;
    }

    if (platform != null) {
      body['platform'] = platform;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/agent/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String? token = responseData['token'];
      if (token != null) {
        await _tokenStorage.saveToken(token);
      } else {
        debugPrint('Login successful, but no token received from backend.');
      }
    }
    return response;
  }

  /// Fetch authenticated agent's profile data
  Future<Map<String, dynamic>> fetchUserData() async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse("$baseUrl/agent/profile"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user data: ${response.body}');
    }
  }

  /// Get agent profile with error handling
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse("$baseUrl/agent/profile"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _tokenStorage.clearToken();
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load profile',
        };
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Update basic agent profile details
  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String area,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse("$baseUrl/agent/update-profile-basic"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'area': area,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  /// Change agent password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse("$baseUrl/agent/change-password"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  /// Update profile picture
  Future<Map<String, dynamic>> updateProfilePicture(File imageFile) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) throw Exception('Not authenticated');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/agent/profile-picture"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(
            responseBody['message'] ?? 'Failed to update profile picture');
      }
    } catch (e) {
      throw Exception('Error updating profile picture: $e');
    }
  }

  /// Logout - clears local tokens and notifies backend
  Future<void> logout() async {
    // Get the token before clearing it locally to send to the backend
    final String? token = await _tokenStorage.getToken();

    if (token != null) {
      try {
        await http.post(
          Uri.parse("$baseUrl/agent/logout"),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (e) {
        debugPrint('Error during logout API call: $e');
      }
    }

    // Clear all local authentication-related data
    await _tokenStorage.clearToken();
    try {
      await FirebaseMessagingService.clearFCMToken();
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }

    // Disconnect chat socket
    SocketService.disconnect();
  }
}
