import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';
import 'package:cribs_arena/services/property_tracking_service.dart';

// Duplicating helper classes for simplicity. In a real app, these would be in shared files.
class NetworkConfig {
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration tokenTimeout = Duration(seconds: 3);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);
}

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

class SavedPropertyService {
  static final String _baseUrl = kUserBaseUrl;
  final http.Client _client;
  final PropertyTrackingService _trackingService;

  SavedPropertyService({http.Client? client})
      : _client = client ?? http.Client(),
        _trackingService = PropertyTrackingService();

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(NetworkConfig.tokenTimeout);
      return prefs.getString(kAuthTokenKey);
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
  }) async {
    try {
      final response = await request().timeout(NetworkConfig.requestTimeout);
      _validateResponse(response);
      return response;
    } on TimeoutException {
      throw NetworkException('Request timed out', NetworkErrorType.timeout);
    } on SocketException {
      throw NetworkException(
          'No internet connection', NetworkErrorType.noConnection);
    } on HttpException catch (e) {
      throw NetworkException(
          'HTTP error: ${e.message}', NetworkErrorType.serverError);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException('Unknown error: $e', NetworkErrorType.unknown);
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final String message =
        'Request failed with status code ${response.statusCode}';
    NetworkErrorType type;
    switch (response.statusCode) {
      case 401:
        type = NetworkErrorType.unauthorized;
        break;
      case 404:
        type = NetworkErrorType.notFound;
        break;
      default:
        type = NetworkErrorType.serverError;
    }
    throw NetworkException(message, type, statusCode: response.statusCode);
  }

  T _decodeJson<T>(String body, T Function(dynamic) decoder) {
    try {
      return decoder(jsonDecode(body));
    } on FormatException {
      throw NetworkException(
          'Invalid JSON response', NetworkErrorType.serverError);
    }
  }

  Future<http.Response> _get(String endpoint) async {
    final headers = await _buildHeaders();
    return _safeRequest(
        request: () =>
            _client.get(Uri.parse('$_baseUrl$endpoint'), headers: headers));
  }

  Future<http.Response> _post(String endpoint, {Object? body}) async {
    final headers = await _buildHeaders();
    return _safeRequest(
        request: () => _client.post(Uri.parse('$_baseUrl$endpoint'),
            headers: headers, body: body != null ? jsonEncode(body) : null));
  }

  Future<http.Response> _delete(String endpoint) async {
    final headers = await _buildHeaders();
    return _safeRequest(
        request: () =>
            _client.delete(Uri.parse('$_baseUrl$endpoint'), headers: headers));
  }

  Future<PropertyListResponse> getSavedProperties({int page = 1}) async {
    final response = await _get('/saved-properties?page=$page');
    return _decodeJson(response.body, (json) {
      final data = json as Map<String, dynamic>;
      final propertiesList =
          (data['data'] as List).map((e) => Property.fromJson(e)).toList();
      final pagination = data['pagination'] as Map<String, dynamic>;
      return PropertyListResponse(
        data: propertiesList,
        currentPage: pagination['current_page'] as int,
        lastPage: pagination['last_page'] as int,
      );
    });
  }

  Future<void> saveProperty(String propertyId) async {
    await _post('/properties/$propertyId/save');
    try {
      // Track this as a lead
      await _trackingService.incrementLeadsCount(propertyId);
    } catch (e) {
      // Silent failure for tracking - don't block user flow
      debugPrint('Failed to track lead increment: $e');
    }
  }

  Future<void> unsaveProperty(String propertyId) async {
    await _delete('/properties/$propertyId/unsave');
    try {
      // Untrack this lead
      await _trackingService.decrementLeadsCount(propertyId);
    } catch (e) {
      // Silent failure for tracking
      debugPrint('Failed to track lead decrement: $e');
    }
  }

  Future<bool> isPropertySaved(String propertyId) async {
    final response = await _get('/properties/$propertyId/is-saved');
    return _decodeJson(
        response.body, (json) => (json['data']['is_saved'] as bool?) ?? false);
  }

  /// Stream that periodically emits the total count of saved properties
  Stream<int> getSavedPropertiesCountStream(
      {Duration interval = const Duration(seconds: 5)}) {
    return Stream.periodic(interval).asyncMap((_) async {
      try {
        int totalSaved = 0;
        int page = 1;

        while (true) {
          final response = await getSavedProperties(page: page);
          totalSaved += response.data.length;
          if (!response.hasNextPage) break;
          page++;
        }

        return totalSaved;
      } catch (e) {
        return 0;
      }
    });
  }

  void dispose() {
    _client.close();
  }
}
