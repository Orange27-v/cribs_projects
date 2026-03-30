import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cribs_agents/services/connectivity_service.dart';
import 'package:cribs_agents/services/firebase_messaging_service.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Define a global key for the navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Define a global RouteObserver for tracking route changes (consistent with arena)
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Define a top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ✅ Initialize Firebase only if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  // Initialize local notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_notification');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // ✅ CREATE THE NOTIFICATION CHANNEL
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'cribs_agents_channel_id',
    'Cribs Agents Notifications',
    description: 'Notifications from Cribs Agents',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // ✅ SHOW NOTIFICATION (Simple text only)
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'cribs_agents_channel_id',
    'Cribs Agents Notifications',
    channelDescription: 'Notifications from Cribs Agents',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
    icon: 'ic_notification',
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails();

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);

  final String title =
      message.data['title'] ?? message.notification?.title ?? 'New Message';
  final String body = message.data['body'] ?? message.notification?.body ?? '';

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    platformChannelSpecifics,
    payload: jsonEncode(message.data),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (Consistent with Arena)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

  // ✅ Initialize Firebase ONLY if not already initialized
  // This handles both cold starts and hot restarts
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  // Run the app
  runApp(
    App(navigatorKey: navigatorKey),
  );

  // ✅ Initialize messaging service AFTER app starts (non-blocking)
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      final FirebaseMessagingService firebaseMessagingService =
          FirebaseMessagingService(navigatorKey);
      await firebaseMessagingService.initialize();
    } catch (e) {
      debugPrint('Error initializing FirebaseMessagingService: $e');
    }

    // ✅ Initialize connectivity service to monitor internet connection
    try {
      final ConnectivityService connectivityService =
          ConnectivityService(navigatorKey);
      await connectivityService.initialize();
    } catch (e) {
      // Handle connectivity service initialization errors silently
      debugPrint('Connectivity service initialization error: $e');
    }
  });
}
