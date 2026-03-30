import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribs_arena/constants.dart'; // Added import

class LegalService {
  final String _baseUrl = kBaseUrl; // Replaced hardcoded URL with kBaseUrl

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kAuthTokenKey); // Use kAuthTokenKey from constants
  }

  Future<Map<String, dynamic>> fetchLegalDocument(String type) async {
    final uri = Uri.parse('$_baseUrl/legal/$type');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to load legal document: ${response.reasonPhrase}');
    }
  }

  Future<void> agreeToTerms(String version) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final uri = Uri.parse('$kUserBaseUrl/agree-to-terms'); // Use kUserBaseUrl
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'version': version}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to record user agreement: ${response.reasonPhrase}');
    }
  }
}
