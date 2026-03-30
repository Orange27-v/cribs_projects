import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/exceptions/network_exception.dart';

// Network Configuration (re-using from PropertyService for consistency)
class NetworkConfig {
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration tokenTimeout = Duration(seconds: 3);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);
}

// Result Type for Better Error Handling (re-using from PropertyService for consistency)
class Result<T> {
  final T? data;
  final NetworkException? error;

  bool get isSuccess => error == null;
  bool get isError => error != null;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class NotificationSettingsService {
  static final String _baseUrl = kBaseUrl;
  final http.Client _client;

  NotificationSettingsService({http.Client? client})
      : _client = client ?? http.Client();

  // Safe token getter with timeout
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

  // Build headers with token
  Future<Map<String, String>> _buildHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Safe HTTP wrapper with retry logic
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

  // Validate HTTP response
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

  // Safe JSON decoder
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

  /// Fetches the user's current notification settings.
  Future<Result<Map<String, bool>>> getNotificationSettings() async {
    try {
      final headers = await _buildHeaders();
      final response = await _safeRequest(
        request: () => _client.get(
          Uri.parse('$_baseUrl/notification-settings'),
          headers: headers,
        ),
      );

      final Map<String, dynamic> jsonResponse = _decodeJson(
        response.body,
        (json) => json as Map<String, dynamic>,
      );

      final Map<String, bool> settings = {};
      jsonResponse.forEach((key, value) {
        if (value is bool) {
          settings[key] = value;
        } else if (value is int) {
          settings[key] = value == 1;
        }
      });
      return Result.success(settings);
    } on NetworkException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(NetworkException(
        'An unexpected error occurred: $e',
        NetworkErrorType.unknown,
      ));
    }
  }

  /// Updates a specific notification setting.
  Future<Result<bool>> updateNotificationSetting(String key, bool value) async {
    try {
      final headers = await _buildHeaders();
      final response = await _safeRequest(
        request: () => _client.put(
          Uri.parse('$_baseUrl/notification-settings'),
          headers: headers,
          body: jsonEncode({key: value}),
        ),
      );

      final Map<String, dynamic> jsonResponse = _decodeJson(
        response.body,
        (json) => json as Map<String, dynamic>,
      );

      if (jsonResponse['message'] ==
          'Notification settings updated successfully.') {
        return Result.success(true);
      } else {
        return Result.failure(NetworkException(
          jsonResponse['message'] ?? 'Failed to update setting',
          NetworkErrorType.serverError,
        ));
      }
    } on NetworkException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(NetworkException(
        'An unexpected error occurred: $e',
        NetworkErrorType.unknown,
      ));
    }
  }

  // Dispose resources
  void dispose() {
    _client.close();
  }
}
