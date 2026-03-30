import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants.dart';
import 'token_storage_service.dart';
import '../models/notification_model.dart';

/// Service for managing agent notifications
class AgentNotificationService {
  static final AgentNotificationService _instance =
      AgentNotificationService._internal();

  factory AgentNotificationService() {
    return _instance;
  }

  AgentNotificationService._internal();

  final String baseUrl = kAgentBaseUrl;
  final TokenStorageService _tokenStorage = TokenStorageService();

  // Stream controllers for real-time updates
  StreamController<List<NotificationModel>>? _notificationsController;
  StreamController<int>? _unreadCountController;
  Timer? _pollingTimer;
  Timer? _unreadCountPollingTimer;

  /// Dispose of all stream controllers and timers (Note: in singleton, might not want to dispose unless app lifecycle requires)
  void dispose() {
    // For singletons in Flutter, usually we don't dispose unless specifically needed
    // but if we do, we should reset the controllers so they can be recreated.
    _notificationsController?.close();
    _unreadCountController?.close();
    _notificationsController = null;
    _unreadCountController = null;
    _pollingTimer?.cancel();
    _unreadCountPollingTimer?.cancel();
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return 0;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final count = data['data']['unread_count'] ?? 0;
          _unreadCountController?.add(count);
          return count;
        }
      }

      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Provides a real-time stream of unread notifications count.
  Stream<int> getUnreadNotificationsCountStream() {
    if (_unreadCountController == null) {
      _unreadCountController = StreamController<int>.broadcast();
      // Initial fetch
      getUnreadCount();
      // Periodic polling
      _unreadCountPollingTimer =
          Timer.periodic(const Duration(seconds: 30), (timer) {
        getUnreadCount();
      });
    }
    return _unreadCountController!.stream;
  }

  /// Get paginated notifications list
  Future<List<NotificationModel>> fetchNotifications(
      {int page = 1, int perPage = 50}) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications?page=$page&per_page=$perPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          List<dynamic> list = [];
          if (data is Map && data['data'] != null) {
            list = data['data'] as List<dynamic>;
          } else if (data is List) {
            list = data;
          }

          final notifications =
              list.map((json) => NotificationModel.fromJson(json)).toList();

          _notificationsController?.add(notifications);
          return notifications;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Provides a real-time stream of notifications list.
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (_notificationsController == null) {
      _notificationsController =
          StreamController<List<NotificationModel>>.broadcast();
      // Initial fetch
      fetchNotifications();
      // Periodic polling
      _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        fetchNotifications();
      });
    }
    return _notificationsController!.stream;
  }

  /// Mark a single notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          fetchNotifications(); // Refresh stream
          getUnreadCount(); // Refresh unread count
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    // Optimistic UI update: Clear unread count locally first
    _unreadCountController?.add(0);

    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          fetchNotifications(); // Refresh stream
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      // If failed, maybe we should re-fetch the real count?
      getUnreadCount();
      return false;
    }
  }
}
