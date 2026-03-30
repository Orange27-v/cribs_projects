import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for password reset operations
class PasswordResetService {
  final String baseUrl = kBaseUrl;

  /// Request password reset - sends reset token to email
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/agent/forgot-password"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'body': body,
      };
    } catch (e) {
      debugPrint('Forgot password error: $e');
      rethrow;
    }
  }

  /// Verify the password reset token
  Future<Map<String, dynamic>> verifyResetToken({
    required String email,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/agent/verify-reset-token"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'token': token,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'body': body,
      };
    } catch (e) {
      debugPrint('Verify reset token error: $e');
      rethrow;
    }
  }

  /// Reset password with verified token
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/agent/reset-password"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': newPassword,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'body': body,
      };
    } catch (e) {
      debugPrint('Reset password error: $e');
      rethrow;
    }
  }
}
