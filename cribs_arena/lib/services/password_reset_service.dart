import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class PasswordResetService {
  final String baseUrl = kBaseUrl;

  /// Send password reset code to email
  Future<Map<String, dynamic>> sendResetCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/password/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      throw Exception('Failed to send reset code: $e');
    }
  }

  /// Verify the reset code
  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/password/verify-code'),
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
      throw Exception('Failed to verify code: $e');
    }
  }

  /// Reset password with verified code
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }
}
