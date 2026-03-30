import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';

class ScheduleService {
  static final String _baseUrl = kBaseUrl;
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;
  static const int _baseDelaySeconds = 2;

  final http.Client _client;
  String? _cachedToken;

  ScheduleService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(kAuthTokenKey);
    return _cachedToken;
  }

  void clearTokenCache() {
    _cachedToken = null;
  }

  Future<http.Response> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final token = authenticated ? await _getToken() : null;

    if (authenticated && token == null) {
      throw Exception('Authentication token not found');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authenticated && token != null) 'Authorization': 'Bearer $token',
    };

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _makeRequest(uri, method, headers, body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        if (response.statusCode == 429 && attempt < _maxRetries - 1) {
          await Future.delayed(
            Duration(seconds: _baseDelaySeconds * (attempt + 1)),
          );
          continue;
        }

        if (response.statusCode == 401) {
          clearTokenCache();
          throw Exception('Unauthorized: Please login again');
        }

        throw Exception(
          'Request failed (${response.statusCode}): ${response.body}',
        );
      } on SocketException {
        if (attempt == _maxRetries - 1) {
          throw Exception('No internet connection');
        }
        await Future.delayed(
          Duration(seconds: _baseDelaySeconds * (attempt + 1)),
        );
      } on TimeoutException {
        if (attempt == _maxRetries - 1) throw Exception('Request timeout');
        await Future.delayed(
          Duration(seconds: _baseDelaySeconds * (attempt + 1)),
        );
      } catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
        await Future.delayed(
          Duration(seconds: _baseDelaySeconds * (attempt + 1)),
        );
      }
    }

    throw Exception('Too many failed attempts for $endpoint');
  }

  Future<http.Response> _makeRequest(
    Uri uri,
    String method,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(uri, headers: headers).timeout(_timeout);
      case 'POST':
        return await _client
            .post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(_timeout);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  Future<List<dynamic>> getAgentInspections() async {
    final response = await _request('/agent/inspections', method: 'GET');
    final data = jsonDecode(response.body);

    if (data['success'] == true && data['data'] != null) {
      // Handle paginated response
      if (data['data'] is Map && data['data']['data'] != null) {
        return data['data']['data'] as List<dynamic>;
      }
      // Handle direct array response
      return data['data'] as List<dynamic>;
    }

    return [];
  }

  void dispose() {
    _client.close();
    clearTokenCache();
  }
}
