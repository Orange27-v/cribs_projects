import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/auth_service.dart';

class NinService {
  static final String _baseUrl = kBaseUrl; // Use your Laravel backend URL
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> verifyNin({
    required String nin,
    required String firstname,
    required String lastname,
    String? dob,
    String? phone,
    String? email,
    String? gender,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/verify/nin'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nin': nin,
        'firstname': firstname,
        'lastname': lastname,
        'dob': dob,
        'phone': phone,
        'email': email,
        'gender': gender,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'Failed to start NIN verification');
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

  Future<Map<String, dynamic>> getNinStatus(String verificationId) async {
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
      throw Exception(errorData['message'] ?? 'Failed to get NIN status');
    }
  }
}
