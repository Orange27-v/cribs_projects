import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cribs_agents/services/socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:cribs_agents/constants.dart';

class ChatService {
  // Use the kChatBaseUrl constant for the API URL
  final String baseUrl = kChatBaseUrl;

  // Singleton instance
  static final ChatService _instance = ChatService._internal();

  factory ChatService() => _instance;

  // Private constructor
  ChatService._internal() {
    // Listen for new messages via socket to update conversation list locally
    // This allows for "Push" updates to the UI without needing a full refresh
    SocketService.messageStream.listen((message) {
      _handleNewMessage(message);
    });

    // Listen for conversation updates (like read receipts)
    SocketService.conversationUpdateStream.listen((convId) {
      if (_currentUserId != null) {
        _fetchAndEmitConversations(_currentUserId!);
      }
    });
  }

  // Local cache for conversations
  List<Map<String, dynamic>> _conversations = [];
  String? _currentUserId; // Track current user ID for refreshing

  // Broadcast controllers so multiple listeners can subscribe
  final _conversationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  final _messagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  final _unreadCountController = StreamController<int>.broadcast();

  // Cache for the currently active conversation messages
  List<Map<String, dynamic>> _currentMessages = [];
  String? _activeConversationId;

  /// Get the currently active conversation ID
  String? get activeConversationId => _activeConversationId;

  /// Clear the active conversation ID
  void clearActiveConversation() {
    _activeConversationId = null;
  }

  /// Find or create a conversation between a user and an agent
  Future<String> findOrCreateConversation({
    required String userId,
    required String agentId,
    required String userName,
    required String userAvatar,
    required String agentName,
    required String agentAvatar,
    List<String>? tags,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'agentId': agentId,
          'userName': userName,
          'userAvatar': userAvatar,
          'agentName': agentName,
          'agentAvatar': agentAvatar,
          'tags': tags ?? [],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        throw Exception('Failed to create conversation: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get a stream of conversations for the user
  Stream<List<Map<String, dynamic>>> getConversationsStream(String userId) {
    // Store the current user ID for later use
    _currentUserId = userId;

    // 1. Emit current cache immediately ensure instant UI
    if (_conversations.isNotEmpty) {
      _conversationsController.add(List.from(_conversations));
    }

    // 2. Fetch latest from server to sync changes
    _fetchAndEmitConversations(userId);

    // 3. Listen to 'conversation_updated' events from socket (e.g. read status changed)
    // We only attach this listener once logically, but StreamBuilder might re-subscribe.
    // Since this is a singleton, we need to be careful not to stack listeners indefinitely
    // if we were adding them to the socket here.
    // But SocketService broadcasts, so we can listen to the SocketService stream here.
    // Note: The global listener in constructor handles 'new_message'.
    // Here we listen for general 'conversation_updated' events (like read receipts).
    return _conversationsController.stream;
  }

  Future<void> _fetchAndEmitConversations(String userId) async {
    try {
      final url = '$baseUrl/conversations/$userId';
      debugPrint('🌐 Fetching conversations from: $url');
      debugPrint('🌐 User ID: $userId');

      final response = await http.get(Uri.parse(url));

      debugPrint('🌐 Response status: ${response.statusCode}');
      debugPrint('🌐 Response body length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        debugPrint('✅ Successfully received conversations');

        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('📊 Parsed ${data.length} conversations from JSON');

        _conversations = List<Map<String, dynamic>>.from(data);

        // Sort: Newest messages first
        _conversations.sort((a, b) {
          final aTime = a['last_message']?['created_at'] != null
              ? DateTime.parse(a['last_message']['created_at'])
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b['last_message']?['created_at'] != null
              ? DateTime.parse(b['last_message']['created_at'])
              : DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        debugPrint(
            '✅ Emitting ${_conversations.length} conversations to stream');
        _conversationsController.add(List.from(_conversations));
        _emitUnreadCount();
      } else {
        debugPrint('❌ Failed to fetch conversations: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');

        if (_conversations.isEmpty) {
          _conversationsController
              .addError('Failed to load: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching conversations: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      if (_conversations.isEmpty) {
        _conversationsController.addError('Connection error: $e');
      }
    }
  }

  /// Handle incoming real-time messages to update the list
  void _handleNewMessage(Map<String, dynamic> message) {
    if (message['conversationId'] == null) return;
    final convId = message['conversationId'];

    // 1. If we are viewing this conversation, update the messages list
    if (_activeConversationId == convId) {
      // Avoid duplicates - check both 'id' and '_id' fields
      final messageId = message['_id'] ?? message['id'];
      final isDuplicate = _currentMessages.any((m) {
        final existingId = m['_id'] ?? m['id'];
        return existingId != null && existingId == messageId;
      });

      if (!isDuplicate && messageId != null) {
        // Ensure the message has the proper structure with sender ID
        // The socket might send 'fromId' but we need to preserve it
        final normalizedMessage = Map<String, dynamic>.from(message);

        // Ensure we have a senderId field for proper sender detection
        if (normalizedMessage['senderId'] == null &&
            normalizedMessage['fromId'] != null) {
          normalizedMessage['senderId'] = normalizedMessage['fromId'];
        }

        _currentMessages.add(normalizedMessage);
        _messagesController.add(List.from(_currentMessages));
      }
    }

    // 2. Update the conversation preview in the list
    final index = _conversations.indexWhere((c) => c['id'] == convId);
    if (index != -1) {
      var conv = _conversations[index];

      // Update last message info
      conv['last_message'] = {
        'message': message['text'],
        'created_at': message['timestamp'] ?? DateTime.now().toIso8601String()
      };

      // Increment unread count if message is from other participant and conversation is not active
      final senderId = (message['senderId'] ?? message['fromId'])?.toString();
      if (senderId != null &&
          senderId != _currentUserId &&
          _activeConversationId != convId) {
        conv['unread_count'] = (conv['unread_count'] as int? ?? 0) + 1;
      }

      // Move to top
      _conversations.removeAt(index);
      _conversations.insert(0, conv);

      _conversationsController.add(List.from(_conversations));
      _emitUnreadCount();
    } else {
      // New conversation we don't have cached - refresh the list
      if (_currentUserId != null) {
        _fetchAndEmitConversations(_currentUserId!);
      }
    }
  }

  /// Calculate and emit the total unread message count
  void _emitUnreadCount() {
    int totalUnread = 0;
    for (var conversation in _conversations) {
      totalUnread += (conversation['unread_count'] as int? ?? 0);
    }
    _unreadCountController.add(totalUnread);
  }

  /// Get a stream of the total unread message count
  Stream<int> getUnreadCountStream(String userId) {
    // Store the current user ID for later use
    _currentUserId = userId;

    // Emit current count immediately
    _emitUnreadCount();

    // Fetch latest conversations to ensure count is up to date
    _fetchAndEmitConversations(userId);

    return _unreadCountController.stream;
  }

  Future<void> refreshConversations(String userId) async {
    await _fetchAndEmitConversations(userId);
  }

  /// Get messages for a specific conversation
  Stream<List<Map<String, dynamic>>> getMessagesStream(String conversationId) {
    _activeConversationId = conversationId;
    _currentMessages =
        []; // Clear previous messages to avoid flash of wrong content

    // Fetch latest
    refreshMessages(conversationId);

    return _messagesController.stream;
  }

  Future<void> refreshMessages(String conversationId) async {
    _activeConversationId = conversationId;
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/messages/$conversationId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _currentMessages = List<Map<String, dynamic>>.from(data);
        _messagesController.add(List.from(_currentMessages));
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/conversations/$conversationId/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      // We could ideally update the local cache 'unread_count' here
      // to reflect the read status immediately.
      final index = _conversations.indexWhere((c) => c['id'] == conversationId);
      if (index != -1) {
        _conversations[index]['unread_count'] = 0;
        _conversationsController.add(List.from(_conversations));
        _emitUnreadCount();
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/conversations/$conversationId'));
      // Remove from local cache
      _conversations.removeWhere((c) => c['id'] == conversationId);
      _conversationsController.add(List.from(_conversations));
      _emitUnreadCount();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessages(
      String conversationId, List<String> messageIds) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/messages/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messageIds': messageIds}),
      );
      // Refresh to be consisten
      refreshMessages(conversationId);
    } catch (e) {
      rethrow;
    }
  }
}
