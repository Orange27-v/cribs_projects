import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for email verification operations
class EmailVerificationService {
  final String baseUrl = kBaseUrl;

  /// Verify email with verification code
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/agent/verify-email"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'body': body,
      };
    } catch (e) {
      debugPrint('Verification error: $e');
      rethrow;
    }
  }

  /// Resend verification code to email
  Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/agent/resend-verification-code"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'body': body,
      };
    } catch (e) {
      debugPrint('Resend code error: $e');
      rethrow;
    }
  }
}
