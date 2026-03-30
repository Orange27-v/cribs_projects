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

// Result Type for Better Error Handling
class Result<T> {
  final T? data;
  final NetworkException? error;

  bool get isSuccess => error == null;
  bool get isError => error != null;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class PropertyService {
  static final String _baseUrl = kBaseUrl;
  final http.Client _client;

  PropertyService({http.Client? client}) : _client = client ?? http.Client();

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

  // GET request
  Future<http.Response> _get(String endpoint) async {
    final headers = await _buildHeaders();
    return _safeRequest(
      request: () => _client.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      ),
    );
  }

  // DELETE request

  // API Methods

  Future<Property> getPropertyDetails(String propertyId) async {
    try {
      final response = await _get('/properties/$propertyId');
      final data = _decodeJson(response.body, (json) {
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          return Property.fromJson(json['data'] as Map<String, dynamic>);
        }
        return Property.fromJson(json as Map<String, dynamic>);
      });
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<PropertyListResponse> getAllProperties({int page = 1}) async {
    try {
      final response = await _get('/properties?page=$page');
      final data = _decodeJson<PropertyListResponse>(
        response.body,
        (json) {
          if (json is Map<String, dynamic>) {
            final propertiesList = (json['data'] as List)
                .map((e) => Property.fromJson(e))
                .toList();
            final pagination = json['pagination'] as Map<String, dynamic>?;
            return PropertyListResponse(
              data: propertiesList,
              currentPage: pagination?['current_page'] as int? ?? 1,
              lastPage: pagination?['last_page'] as int? ?? 1,
            );
          }
          throw NetworkException(
            'Unexpected JSON format for properties list',
            NetworkErrorType.serverError,
          );
        },
      );
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Property> getPropertyById(String propertyId) async {
    try {
      final response = await _get('/properties/$propertyId');
      final property = _decodeJson(response.body, (json) {
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          return Property.fromJson(json['data']);
        }
        return Property.fromJson(json);
      });
      return property;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Property>> getPropertiesByAgentId(String agentId) async {
    try {
      final url = '/agents/$agentId/properties';
      final response = await _get(url);
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
            'Unexpected JSON format for agent properties list',
            NetworkErrorType.serverError,
          );
        },
      );
      return properties;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Property>> getNewPropertiesByAgentId(String agentId) async {
    try {
      final url = '/agents/$agentId/properties/new';
      final response = await _get(url);
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
            'Unexpected JSON format for new properties',
            NetworkErrorType.serverError,
          );
        },
      );
      return properties;
    } catch (e) {
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    _client.close();
  }
}

// Response Models
class PropertyListResponse {
  final List<Property> data;
  final int currentPage;
  final int lastPage;

  PropertyListResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}
