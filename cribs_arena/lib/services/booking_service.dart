import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';

class BookingService {
  static const Duration _timeout = Duration(seconds: 60);
  static const int _maxRetries = 3;
  static const int _baseDelaySeconds = 2;

  final http.Client _client;
  String? _cachedToken;

  BookingService({http.Client? client}) : _client = client ?? http.Client();

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
    String url, {
    String method = 'POST',
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse(url);
    final token = authenticated ? await _getToken() : null;

    if (authenticated && token == null) {
      throw Exception('Authentication token not found');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
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
              Duration(seconds: _baseDelaySeconds * (attempt + 1)));
          continue;
        }

        if (response.statusCode == 401) {
          clearTokenCache();
          throw Exception('Unauthorized: Please login again');
        }

        throw Exception(
            'Request failed (${response.statusCode}): ${response.body}');
      } on SocketException {
        if (attempt == _maxRetries - 1) {
          throw Exception('No internet connection');
        }
        await Future.delayed(
            Duration(seconds: _baseDelaySeconds * (attempt + 1)));
      } on TimeoutException {
        if (attempt == _maxRetries - 1) {
          throw Exception('Request timeout');
        }
        await Future.delayed(
            Duration(seconds: _baseDelaySeconds * (attempt + 1)));
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(
            Duration(seconds: _baseDelaySeconds * (attempt + 1)));
      }
    }

    throw Exception('Too many failed attempts for $url');
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
            .post(uri,
                headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(_timeout);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  Future<http.Response> bookInspection(Map<String, dynamic> data) async {
    return await _request(
      '$kUserBaseUrl/inspections',
      body: data,
    );
  }

  Future<List<dynamic>> getMyBookings() async {
    final response = await _request(
      '$kUserBaseUrl/bookings',
      method: 'GET',
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> initializePaystackTransaction(
      double amount, String email, Map<String, dynamic> metadata) async {
    final response = await _request(
      '$kUserBaseUrl/paystack/initialize',
      method: 'POST',
      body: {
        'amount': amount,
        'email': email,
        'metadata': metadata,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to initialize Paystack transaction: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> finalizeBooking({
    required int agentId,
    int? propertyDbId,
    required String paystackReference,
    required String inspectionDate,
    required String inspectionTime,
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await _request(
      '$kUserBaseUrl/bookings/finalize',
      method: 'POST',
      body: {
        'agent_id': agentId,
        if (propertyDbId != null) 'property_id': propertyDbId,
        'paystack_reference': paystackReference,
        'inspection_date': inspectionDate,
        'inspection_time': inspectionTime,
        'amount': amount,
        'payment_method': paymentMethod,
      },
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to finalize booking: ${response.body}');
    }
  }

  /// Fetches the current platform fee from the backend
  Future<double> getPlatformFee() async {
    final response = await _request(
      '$kBaseUrl/general/platform-fee',
      method: 'GET',
      authenticated: false,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data']['platform_fee'] as num).toDouble();
      }
      throw Exception('Invalid platform fee response');
    } else {
      throw Exception('Failed to fetch platform fee: ${response.body}');
    }
  }

  void dispose() {
    _client.close();
    clearTokenCache();
  }
}
