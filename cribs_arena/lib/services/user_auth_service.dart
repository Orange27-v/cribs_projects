import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/services/auth_service.dart';
import 'firebase_messaging_service.dart';
import './user_registration_service.dart';
import './user_login_service.dart';

class UserAuthService extends AuthService {
  late final UserRegistrationService registrationService;
  late final UserLoginService loginService;

  UserAuthService() {
    registrationService = UserRegistrationService();
    loginService = UserLoginService(this); // Removed unnecessary cast
  }

  // Fetch user data
  Future<Map<String, dynamic>> fetchUserData() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse("$kUserBaseUrl/profile"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Failed to fetch user data: Request timed out.');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await clearToken();
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to fetch user data: ${response.body}');
      }
    } catch (e) {
      debugPrint('Fetch user data error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    final String? token = await getToken();

    // Call backend logout endpoint
    if (token != null) {
      try {
        await http.post(
          Uri.parse("$kUserBaseUrl/logout"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('Logout request timed out');
            return http.Response('{"message": "Timeout"}', 408);
          },
        );
      } catch (e) {
        debugPrint('Error during logout API call: $e');
      }
    }

    // Clear local data
    await clearToken();

    // Clear FCM token
    try {
      await FirebaseMessagingService.clearFCMToken(); // Updated to static call
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }

  // Removed saveFCMToken method as it's handled by FirebaseMessagingService

  // Removed initializeFirebaseMessaging method as it's handled in main.dart

  // Verify authentication state
  Future<bool> verifyAuthState() async {
    final token = await getToken();

    if (token == null) {
      return false;
    }

    // Verify token with backend
    try {
      await fetchUserData();
      return true;
    } catch (e) {
      debugPrint('Auth verification failed: $e');
      await logout();
      return false;
    }
  }
}
