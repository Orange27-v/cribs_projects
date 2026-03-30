import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'chat_service.dart';

class FirebaseMessagingService {
  final AuthService _authService = AuthService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey;

  FirebaseMessagingService(this.navigatorKey);

  Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get initial token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      debugPrint('Initial FCM token: $fcmToken');
      await _sendTokenToServer(fcmToken);
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      debugPrint('FCM token refreshed: $token');
      _sendTokenToServer(token);
    });

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle interaction when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

    // Handle interaction when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('onDidReceiveNotificationResponse: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );

    // ✅ CREATE ANDROID NOTIFICATION CHANNEL
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'cribs_arena_channel_id', // Must match the ID in AndroidManifest.xml
      'Cribs Arena Notifications',
      description: 'Notifications from Cribs Arena',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('✅ Android notification channel created: ${channel.id}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    // If this is a chat message, check if we are already viewing this conversation
    final String? conversationId = message.data['conversationId'];
    if (conversationId != null) {
      final String? activeConvId = ChatService().activeConversationId;
      if (activeConvId == conversationId) {
        debugPrint(
            '💬 Already in conversation $conversationId, suppressing foreground notification');
        // Still refresh notification count to keep UI synced if needed
        NotificationService().fetchLatestUnreadCount();
        return;
      }
    }

    if (message.notification != null ||
        (message.data.containsKey('title') &&
            message.data.containsKey('body'))) {
      debugPrint('🔔 Foreground message received, showing local notification');
      await _showLocalNotification(message);
    }

    // Refresh notification count
    NotificationService().fetchLatestUnreadCount();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Prioritize data payload for title and body, fallback to notification payload
    final String? title = message.data['title'] ?? message.notification?.title;
    final String? body = message.data['body'] ?? message.notification?.body;

    if (title == null || body == null) {
      debugPrint('Skipping local notification: title or body is null.');
      return;
    }

    // Simple notification with app icon only (no large image)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'cribs_arena_channel_id',
      'Cribs Arena Notifications',
      channelDescription: 'Notifications from Cribs Arena',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: 'ic_notification', // Use app icon
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode, // Use unique ID for each notification
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        _handleNotificationNavigation(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) {
      debugPrint(
          'App opened from terminated state by notification: ${message.data}');
      // Add a small delay to ensure navigation is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationNavigation(message.data);
      });
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App opened from background by notification: ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint('Navigating with data: $data');
    final String? type = data['type'];

    if (type == null) {
      debugPrint('⚠️ Notification data missing type field.');
      return;
    }

    // Helper to get ID from data payload, checking both snake_case and camelCase
    String? getId(List<String> keys) {
      for (final key in keys) {
        if (data.containsKey(key) && data[key] != null) {
          return data[key].toString();
        }
      }
      return null;
    }

    switch (type) {
      case 'chat':
        final String? conversationId =
            getId(['conversationId', 'conversation_id']);
        final String? chatPartnerName =
            data['chatPartnerName'] ?? data['chat_partner_name'];
        if (conversationId != null) {
          debugPrint('Navigating to chat with conversationId: $conversationId');
          navigatorKey.currentState?.pushNamed(
            '/chat',
            arguments: {
              'conversationId': conversationId,
              'chatPartnerName': chatPartnerName,
            },
          );
        } else {
          debugPrint('⚠️ Chat notification missing conversationId.');
        }
        break;

      case 'booking_update':
      case 'booking_confirmed':
      case 'booking_rejected':
      case 'booking_cancelled':
        final String? bookingId =
            getId(['bookingId', 'booking_id', 'inspection_id', 'inspectionId']);
        if (bookingId != null) {
          debugPrint('Navigating to booking details for bookingId: $bookingId');
          navigatorKey.currentState?.pushNamed(
            '/booking_details',
            arguments: {'bookingId': bookingId},
          );
        } else {
          debugPrint('⚠️ Booking notification missing bookingId.');
        }
        break;

      case 'inspection_update':
      case 'inspection_scheduled':
        final String? inspectionId =
            getId(['inspectionId', 'inspection_id', 'bookingId', 'booking_id']);
        if (inspectionId != null) {
          debugPrint(
              'Navigating to inspection details for inspectionId: $inspectionId');
          navigatorKey.currentState?.pushNamed(
            '/inspection_details',
            arguments: {'inspectionId': inspectionId},
          );
        } else {
          debugPrint('⚠️ Inspection notification missing inspectionId.');
        }
        break;

      case 'new_listing':
        final String? propertyId = getId(['propertyId', 'property_id']);
        if (propertyId != null) {
          debugPrint(
              'Navigating to property details for propertyId: $propertyId');
          navigatorKey.currentState?.pushNamed(
            '/property_details',
            arguments: {'propertyId': propertyId},
          );
        } else {
          debugPrint('⚠️ New listing notification missing propertyId.');
        }
        break;

      case 'payment_confirmation':
      case 'payment_received':
      case 'payment_successful':
        final String? transactionId =
            getId(['transactionId', 'transaction_id']);
        if (transactionId != null) {
          debugPrint(
              'Navigating to transaction details for transactionId: $transactionId');
          navigatorKey.currentState?.pushNamed(
            '/transaction_details',
            arguments: {'transactionId': transactionId},
          );
        } else {
          debugPrint('⚠️ Payment notification missing transactionId.');
        }
        break;

      case 'subscription':
        navigatorKey.currentState?.pushNamed('/profile'); // Fallback for now
        break;

      default:
        debugPrint('⚠️ Unknown notification type: $type. Navigating to home.');
        navigatorKey.currentState?.pushReplacementNamed(
            '/'); // Use pushReplacement to ensure we're at home
        break;
    }
  }

  Future<void> _sendTokenToServer(String fcmToken, {String? authToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = authToken ?? await _authService.getToken();

    if (token == null) {
      debugPrint('User token is null. Saving FCM token for later sending.');
      await prefs.setString(kPendingFCMTokenKey, fcmToken);
      return;
    }

    // Determine the platform
    String platform;
    if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else {
      platform = 'unknown';
    }

    debugPrint('Sending FCM token to server: $kBaseUrl/device-tokens');

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/device-tokens'), // Corrected endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'fcm_token': fcmToken,
          'platform': platform, // Add platform information
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token sent to server successfully.');
        await prefs.setString('fcm_token', fcmToken);
      } else if (response.statusCode == 401) {
        debugPrint(
            '❌ Failed to send FCM token. Status: 401 Unauthenticated. Clearing auth token and saving FCM for retry.');
        await _authService.clearToken(); // Clear the invalid auth token
        await prefs.setString(
            kPendingFCMTokenKey, fcmToken); // Save FCM for later
      } else {
        debugPrint(
            '❌ Failed to send FCM token. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token to server: $e');
    }
  }

  Future<String?> getStoredFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  static Future<void> clearFCMToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      debugPrint('✅ FCM token cleared');
    } catch (e) {
      debugPrint('❌ Error clearing FCM token: $e');
    }
  }

  Future<void> sendPendingFCMToken(String authToken) async {
    final prefs = await SharedPreferences.getInstance();
    final String? pendingFCMToken = prefs.getString(kPendingFCMTokenKey);

    if (pendingFCMToken != null) {
      debugPrint('Attempting to send pending FCM token: $pendingFCMToken');
      await _sendTokenToServer(pendingFCMToken, authToken: authToken);
      await prefs.remove(kPendingFCMTokenKey);
      debugPrint('Pending FCM token sent and cleared.');
    }
  }

  Future<void> sendConfirmToken() async {
    // Wrapper for screens to call easily
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _sendTokenToServer(token);
    }
  }

  // Backwards compatibility method for LoginScreen & Onboarding
  Future<void> sendTokenToServer() async {
    final token = await _authService.getToken();
    if (token != null) {
      await sendPendingFCMToken(token);
    }
    await sendConfirmToken();
  }
}
