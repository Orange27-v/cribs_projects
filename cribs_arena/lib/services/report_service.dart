import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/services/user_auth_service.dart';

class ReportService {
  final String _baseUrl = kBaseUrl;
  final UserAuthService _authService = UserAuthService();

  Future<http.Response> submitReport({
    required int agentId,
    required String issue,
    String? details,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final url = Uri.parse('$_baseUrl/agents/$agentId/report');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'issue': issue,
      'details': details,
    });

    final response = await http.post(url, headers: headers, body: body);
    return response;
  }
}
