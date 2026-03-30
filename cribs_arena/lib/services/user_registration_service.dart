import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:flutter/foundation.dart';

class UserRegistrationService {
  Future<http.Response> register({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String area,
    required double latitude,
    required double longitude,
    required String password,
    String? fcmToken,
    String? platform,
  }) async {
    try {
      final body = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
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

      final response = await http
          .post(
        Uri.parse("$kUserBaseUrl/register"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Registration request timed out. Please try again.');
        },
      );

      return response;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }
}
