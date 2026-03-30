import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cribs_agents/constants.dart'; // Import constants.dart

class SocketService {
  static io.Socket? _socket;

  static final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _onlineStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<String> _conversationUpdateController =
      StreamController<String>.broadcast();

  static Stream<Map<String, dynamic>> get messageStream =>
      _messageController.stream;
  static Stream<Map<String, dynamic>> get onlineStatusStream =>
      _onlineStatusController.stream;
  static Stream<String> get conversationUpdateStream =>
      _conversationUpdateController.stream;

  static String? _connectedUserId;

  static void connect(String userId) {
    if (_socket != null && _socket!.connected) {
      if (_connectedUserId == userId) {
        debugPrint('🔌 Socket already connected for: $userId');
        return;
      }
      debugPrint(
          '🔄 Switching user from $_connectedUserId to $userId - Reconnecting...');
      disconnect();
    }

    _connectedUserId = userId;

    debugPrint('🔌 Connecting socket for: $userId');
    debugPrint('📡 Chat server: $kChatBaseUrl');

    _socket = io.io(
      kChatBaseUrl, // Use kChatBaseUrl from constants.dart
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected successfully');
      _socket!.emit('register', userId);
      debugPrint('📝 Registered with userId: $userId');
    });

    // Handle incoming new messages from others
    _socket!.on('new_message', (data) {
      debugPrint('📬 Received new_message: ${data.toString()}');
      if (data is String) {
        try {
          _messageController.add(Map<String, dynamic>.from(jsonDecode(data)));
        } catch (e) {
          _messageController.add(Map<String, dynamic>.from(data as Map));
        }
      } else {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    // Handle successfully sent messages (acknowledgment)
    _socket!.on('message_sent', (data) {
      debugPrint('✉️ Received message_sent acknowledgment');
      if (data is String) {
        try {
          _messageController.add(Map<String, dynamic>.from(jsonDecode(data)));
        } catch (e) {
          _messageController.add(Map<String, dynamic>.from(data as Map));
        }
      } else {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    // Handle online status updates
    _socket!.on('user_online_status', (data) {
      debugPrint('👤 User online status update: ${data.toString()}');
      _onlineStatusController.add(Map<String, dynamic>.from(data));
    });

    // Handle conversation list updates
    _socket!.on('conversation_updated', (data) {
      if (data != null && data['conversationId'] != null) {
        debugPrint('🔄 Conversation updated: ${data['conversationId']}');
        _conversationUpdateController.add(data['conversationId'].toString());
      }
    });

    _socket!.on('message_error', (data) {
      debugPrint('❌ Message error: ${data.toString()}');
    });

    _socket!.onConnectError((err) {
      debugPrint('❌ Socket connection error: $err');
    });

    _socket!.onError((err) {
      debugPrint('❌ Socket error: $err');
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔌 Socket disconnected');
    });
  }

  static void sendMessage(Map<String, dynamic> messageData) {
    if (_socket != null && _socket!.connected) {
      // Encode entire message as JSON to prevent Dart's toString() from mangling nested objects
      final jsonMessage = jsonEncode(messageData);
      debugPrint('📤 Sending message: $jsonMessage');
      _socket!.emit('send_message', jsonMessage);
    } else {
      debugPrint('❌ Socket not connected, cannot send message.');
    }
  }

  static void disconnect() {
    debugPrint('🔌 Disconnecting socket...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectedUserId = null;
  }

  static bool isConnected() {
    return _socket?.connected ?? false;
  }
}
