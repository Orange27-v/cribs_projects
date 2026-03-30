import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart'; // Assuming AuthService contains saveToken

class UserLoginService {
  final AuthService _authService;

  UserLoginService(this._authService);

  Future<http.Response> login({
    required String email,
    required String password,
    String? fcmToken,
    String? platform,
  }) async {
    try {
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

      final response = await http
          .post(
        Uri.parse("$kUserBaseUrl/login"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Login request timed out. Please try again.');
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String? token = responseData['token'];

          if (token != null && token.isNotEmpty) {
            await _authService.saveToken(token);
          } else {
            debugPrint(
                'Warning: Login successful but no token received from backend.');
          }
          return response;
        } on FormatException {
          throw Exception(
              'Invalid response format from server. Expected JSON, got HTML/malformed data.');
        }
      } else if (response.statusCode == 403) {
        // Return 403 response so UI can handle email verification flow
        return response;
      } else {
        String errorMessage =
            'Login failed with status ${response.statusCode}.';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          // Check for 'error' key which is common in Laravel responses
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } on FormatException {
          errorMessage = '$errorMessage Raw response: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }
}
