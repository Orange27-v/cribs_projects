import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';
import 'package:cribs_arena/models/notification_model.dart';

// Re-using the Result and NetworkConfig from notification_settings_service.dart
class NetworkConfig {
  static const Duration requestTimeout = Duration(seconds: 10);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);
}

class Result<T> {
  final T? data;
  final NetworkException? error;

  bool get isSuccess => error == null;
  bool get isError => error != null;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal({http.Client? client})
      : _client = client ?? http.Client();

  static final String _baseUrl = kBaseUrl;
  final http.Client _client;

  // Stream controller for notifications
  StreamController<List<NotificationModel>>? _notificationsController;
  Timer? _pollingTimer;
  String? _token;

  // Stream controller for unread notifications count
  StreamController<int>? _unreadCountController;
  Timer? _unreadCountPollingTimer;

  void setAuthToken(String token) {
    _token = token;
  }

  Future<Map<String, String>> _buildHeaders(String token) async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
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
    throw NetworkException(
      'Request failed with status ${response.statusCode}: ${response.body}',
      NetworkException.fromStatusCode(response.statusCode),
      statusCode: response.statusCode,
    );
  }

  T _decodeJson<T>(String body, T Function(dynamic) decoder) {
    try {
      return decoder(jsonDecode(body));
    } on FormatException catch (e) {
      throw NetworkException(
          'Invalid JSON response: $e', NetworkErrorType.serverError);
    }
  }

  // Internal fetch logic used by both stream and one-time fetch for notifications list
  Future<List<NotificationModel>> _internalFetchNotifications(
      String token) async {
    debugPrint('🔔 Fetching notifications from: $_baseUrl/notifications');
    debugPrint(
        '🔔 Auth token: ${token.substring(0, 20)}...'); // Show first 20 chars

    try {
      final headers = await _buildHeaders(token);
      debugPrint('🔔 Request headers prepared');

      final response = await _safeRequest(
        request: () => _client.get(
          Uri.parse('$_baseUrl/notifications'),
          headers: headers,
        ),
      );

      // debugPrint(
      //     '🔔 Notifications API response status: ${response.statusCode}');
      // debugPrint('🔔 Notifications API response body: ${response.body}');

      final Map<String, dynamic> responseData =
          _decodeJson(response.body, (json) => json);
      final List<dynamic> data = responseData['data'];

      // debugPrint('🔔 Number of notifications received: ${data.length}');

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching notifications: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Internal fetch logic for unread notifications count
  Future<int> _internalFetchUnreadCount(String token) async {
    final headers = await _buildHeaders(token);
    final uri = Uri.parse('$_baseUrl/notifications/unread-count');
    try {
      final response = await _safeRequest(
        request: () => _client.get(
          uri,
          headers: headers,
        ),
      );
      final Map<String, dynamic> responseData =
          _decodeJson(response.body, (json) => json);
      final int count = responseData['unread_count'] ?? 0;
      return count;
    } on NetworkException catch (e) {
      debugPrint('NetworkException fetching unread count: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      rethrow;
    }
  }

  // Public method to manually trigger a refresh for notifications list
  Future<void> fetchLatestNotifications() async {
    if (_token == null) return;
    if (_notificationsController == null ||
        _notificationsController!.isClosed) {
      return;
    }
    try {
      final notifications = await _internalFetchNotifications(_token!);
      if (!_notificationsController!.isClosed) {
        _notificationsController!.add(notifications);
      }
    } catch (e) {
      if (!_notificationsController!.isClosed) {
        _notificationsController!.addError(e);
      }
    }
  }

  // Public method to manually trigger a refresh for unread count
  Future<void> fetchLatestUnreadCount() async {
    if (_token == null) {
      // If no token, emit 0 to show no notifications
      if (_unreadCountController != null && !_unreadCountController!.isClosed) {
        _unreadCountController!.add(0);
      }
      return;
    }
    if (_unreadCountController == null || _unreadCountController!.isClosed) {
      return;
    }
    try {
      final count = await _internalFetchUnreadCount(_token!);
      if (!_unreadCountController!.isClosed) {
        _unreadCountController!.add(count);
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      // On error, emit 0 instead of error to prevent StreamBuilder from showing error state
      // This ensures the UI continues to work even if the API is temporarily unavailable
      if (!_unreadCountController!.isClosed) {
        _unreadCountController!.add(0);
      }
    }
  }

  // Returns a stream that periodically fetches notifications list
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_notificationsController == null) {
      _notificationsController =
          StreamController<List<NotificationModel>>.broadcast();
      // Initial fetch
      fetchLatestNotifications();
      // Periodic polling
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        fetchLatestNotifications();
      });
    }
    return _notificationsController!.stream;
  }

  // Returns a stream that periodically fetches unread notifications count
  Stream<int> getUnreadNotificationsCountStream() {
    if (_unreadCountController == null) {
      _unreadCountController = StreamController<int>.broadcast();
      // Emit initial value of 0 immediately
      _unreadCountController!.add(0);
      // Initial fetch if token is available
      if (_token != null) {
        fetchLatestUnreadCount();
      }
      // Periodic polling
      _unreadCountPollingTimer =
          Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_token != null) {
          fetchLatestUnreadCount();
        }
      });
    }
    return _unreadCountController!.stream;
  }

  Future<Result<void>> markNotificationAsRead(String notificationId) async {
    if (_token == null) {
      return Result.failure(
          NetworkException("Not authenticated", NetworkErrorType.unauthorized));
    }
    try {
      final headers = await _buildHeaders(_token!);
      await _safeRequest(
        request: () => _client.post(
          Uri.parse('$_baseUrl/notifications/$notificationId/mark-as-read'),
          headers: headers,
        ),
      );
      // After marking as read, refresh the streams
      fetchLatestNotifications();
      fetchLatestUnreadCount(); // Refresh unread count as well
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<void>> markAllAsRead() async {
    if (_token == null) {
      return Result.failure(
          NetworkException("Not authenticated", NetworkErrorType.unauthorized));
    }
    try {
      final headers = await _buildHeaders(_token!);
      await _safeRequest(
        request: () => _client.post(
          Uri.parse('$_baseUrl/notifications/mark-all-as-read'), // New endpoint
          headers: headers,
        ),
      );
      fetchLatestNotifications();
      fetchLatestUnreadCount();
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.failure(e);
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _notificationsController?.close();
    _unreadCountPollingTimer?.cancel();
    _unreadCountController?.close();
  }
}
