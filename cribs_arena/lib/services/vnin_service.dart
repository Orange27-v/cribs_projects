import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/services/auth_service.dart';

class VninService {
  static final String _baseUrl = kBaseUrl; // Use your Laravel backend URL
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> verifyVnin({
    required String vnin,
    required String firstname,
    required String lastname,
    String? dob,
    String? gender,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/verify/vnin'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vnin': vnin,
        'firstname': firstname,
        'lastname': lastname,
        'dob': dob,
        'gender': gender,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'Failed to start vNIN verification');
    }
  }

  Future<Map<String, dynamic>> checkExistingVerification(String type) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/verify/check/$type'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'Failed to check existing verification');
    }
  }

  Future<Map<String, dynamic>> getVninStatus(String verificationId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/verify/status/$verificationId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to get vNIN status');
    }
  }
}
