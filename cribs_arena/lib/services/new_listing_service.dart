import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';

// Network Configuration
class NetworkConfig {
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration tokenTimeout = Duration(seconds: 3);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);
}

class NewListingService {
  static final String _baseUrl = kBaseUrl;
  final http.Client _client;

  NewListingService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(NetworkConfig.tokenTimeout);
      return prefs.getString(kAuthTokenKey);
    } on TimeoutException {
      throw NetworkException(
        'Token retrieval timed out',
        NetworkErrorType.timeout,
      );
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>> _buildHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _safeRequest({
    required Future<http.Response> Function() request,
    int retryCount = 0,
  }) async {
    try {
      final response = await request().timeout(NetworkConfig.requestTimeout);
      _validateResponse(response);
      return response;
    } on TimeoutException {
      if (retryCount < NetworkConfig.maxRetries) {
        await Future.delayed(NetworkConfig.retryDelay);
        return _safeRequest(request: request, retryCount: retryCount + 1);
      }
      throw NetworkException(
        'Request timed out after ${NetworkConfig.maxRetries} retries',
        NetworkErrorType.timeout,
      );
    } on SocketException {
      throw NetworkException(
        'No internet connection',
        NetworkErrorType.noConnection,
      );
    } on HttpException catch (e) {
      throw NetworkException(
        'HTTP error: ${e.message}',
        NetworkErrorType.serverError,
      );
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Unknown error: $e',
        NetworkErrorType.unknown,
      );
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final statusCode = response.statusCode;
    NetworkErrorType errorType;
    String message;

    switch (statusCode) {
      case 400:
        errorType = NetworkErrorType.badRequest;
        message = 'Bad request';
        break;
      case 401:
        errorType = NetworkErrorType.unauthorized;
        message = 'Unauthorized - please log in again';
        break;
      case 404:
        errorType = NetworkErrorType.notFound;
        message = 'Resource not found';
        break;
      case 500:
      case 502:
      case 503:
        errorType = NetworkErrorType.serverError;
        message = 'Server error';
        break;
      default:
        errorType = NetworkErrorType.unknown;
        message = 'Request failed with status $statusCode';
    }

    throw NetworkException(
      '$message: ${response.body}',
      errorType,
      statusCode: statusCode,
    );
  }

  T _decodeJson<T>(String body, T Function(dynamic) decoder) {
    if (body.isEmpty) {
      throw NetworkException(
        'Empty response body',
        NetworkErrorType.serverError,
      );
    }

    try {
      final decoded = jsonDecode(body);
      return decoder(decoded);
    } on FormatException catch (e) {
      throw NetworkException(
        'Invalid JSON response: $e',
        NetworkErrorType.serverError,
      );
    }
  }

  Future<http.Response> _get(String endpoint) async {
    final headers = await _buildHeaders();
    return _safeRequest(
      request: () => _client.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      ),
    );
  }

  Future<List<Property>> getNewListingsNearby(
    double latitude,
    double longitude, {
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _get(
        '/properties/new-listings-nearby?latitude=$latitude&longitude=$longitude',
      );
      final properties = _decodeJson<List<Property>>(
        response.body,
        (json) {
          if (json is Map<String, dynamic> && json.containsKey('data')) {
            final data = json['data'] as List;
            return data.map((e) => Property.fromJson(e)).toList();
          } else if (json is List) {
            return json.map((e) => Property.fromJson(e)).toList();
          }
          throw NetworkException(
            'Unexpected JSON format for new listings',
            NetworkErrorType.serverError,
          );
        },
      );
      return properties;
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
