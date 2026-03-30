import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class EmailVerificationService {
  final String baseUrl = kBaseUrl;

  /// Verify email with code
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/email/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'Network error: $e'},
      };
    }
  }

  /// Resend verification code
  Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/email/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'Network error: $e'},
      };
    }
  }
}
