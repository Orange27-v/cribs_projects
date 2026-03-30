import 'dart:async';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/screens/chat/components/add_tag_bottom_sheet.dart';
import 'package:cribs_arena/screens/chat/conversation.dart';
import 'package:cribs_arena/screens/notification/notifications_screen.dart';
import 'package:cribs_arena/screens/schedule/schedule_screen.dart';
import 'package:cribs_arena/screens/components/modern_header.dart';
import 'package:cribs_arena/services/chat_service.dart';
import 'package:cribs_arena/services/socket_service.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cribs_arena/utils/error_handler.dart';
import '../../widgets/widgets.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class Chat {
  final String id;
  final String otherParticipantId;
  final String imageUrl;
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final List<String> tags;

  const Chat({
    required this.id,
    required this.otherParticipantId,
    required this.imageUrl,
    required this.name,
    required this.message,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.tags = const [],
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    final otherParticipant = json['other_participant'] as Map<String, dynamic>;
    final lastMessage = json['last_message'] as Map<String, dynamic>?;

    return Chat(
      id: json['id'] as String,
      otherParticipantId: otherParticipant['id'] as String,
      imageUrl: otherParticipant['profile_picture_url'] as String? ?? '',
      name: otherParticipant['name'] as String? ?? 'Unknown',
      message: lastMessage?['message'] as String? ?? 'No messages yet',
      time: lastMessage != null
          ? _formatTime(lastMessage['created_at'] as String)
          : '',
      unreadCount: json['unread_count'] as int? ?? 0,
      isOnline: otherParticipant['is_online'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  static String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat.jm().format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat.E().format(dateTime);
      } else {
        return DateFormat.MMMd().format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  Chat copyWith({
    String? id,
    String? otherParticipantId,
    String? imageUrl,
    String? name,
    String? message,
    String? time,
    int? unreadCount,
    bool? isOnline,
    List<String>? tags,
  }) {
    return Chat(
      id: id ?? this.id,
      otherParticipantId: otherParticipantId ?? this.otherParticipantId,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      message: message ?? this.message,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      tags: tags ?? this.tags,
    );
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatList();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentUserId != null) {
      _chatService.refreshConversations(_currentUserId!);
    }
  }

  Future<void> _initializeChatList() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rawUserId = userProvider.user?['user_id'].toString();

    if (rawUserId == null) return;

    setState(() {
      _currentUserId = 'user_$rawUserId';
    });

    if (!SocketService.isConnected()) {
      SocketService.connect(_currentUserId!);
    }
  }

  void _navigateToConversation(Chat chat) {
    if (chat.unreadCount > 0 && _currentUserId != null) {
      _chatService.markAsRead(chat.id, _currentUserId!);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          conversationId: chat.id,
          otherParticipantId: chat.otherParticipantId,
          agentName: chat.name,
          agentImageUrl: chat.imageUrl,
        ),
      ),
    ).then((_) {
      if (_currentUserId != null) {
        _chatService.refreshConversations(_currentUserId!);
      }
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatService.deleteConversation(conversationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation deleted'),
            backgroundColor: kGreen,
            duration: Duration(seconds: 2),
          ),
        );

        if (_currentUserId != null) {
          _chatService.refreshConversations(_currentUserId!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: kRed,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: kWhite,
              onPressed: () => _deleteConversation(conversationId),
            ),
          ),
        );
      }
      rethrow;
    }
  }

  void _handleTagsUpdated() {
    if (_currentUserId != null) {
      _chatService.refreshConversations(_currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildChatList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ModernHeader(
      title: 'Messages',
      onCalendarPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyScheduleScreen(),
          ),
        );
      },
      onNotificationPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      },
    );
  }

  Widget _buildChatList() {
    if (_currentUserId == null) {
      return const Center(child: CustomLoadingIndicator());
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getConversationsStream(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CustomLoadingIndicator());
        }

        if (snapshot.hasError) {
          return NetworkErrorWidget(
            errorMessage: getErrorMessage(snapshot.error),
            title: 'Unable to Load Messages',
            icon: Icons.chat_bubble_outline,
            onRefresh: () {
              _chatService.refreshConversations(_currentUserId!);
            },
          );
        }

        final chats = _parseChats(snapshot.data ?? []);

        if (chats.isEmpty) {
          return _buildEmptyState();
        }

        return _buildChatListView(chats);
      },
    );
  }

  List<Chat> _parseChats(List<Map<String, dynamic>> rawConversations) {
    return rawConversations
        .map((json) {
          try {
            return Chat.fromJson(json);
          } catch (e) {
            return null;
          }
        })
        .whereType<Chat>()
        .toList();
  }

  Widget _buildEmptyState() {
    return CustomRefreshIndicator(
      onRefresh: () => _chatService.refreshConversations(_currentUserId!),
      color: kPrimaryColor,
      backgroundColor: kWhite,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: const _EmptyChatsView(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatListView(List<Chat> chats) {
    return CustomRefreshIndicator(
      onRefresh: () => _chatService.refreshConversations(_currentUserId!),
      color: kPrimaryColor,
      backgroundColor: kWhite,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: chats.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: kGrey.withAlpha(26),
          indent: 88,
        ),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _DismissibleChatItem(
            chat: chat,
            onDelete: () => _deleteConversation(chat.id),
            onTap: () => _navigateToConversation(chat),
            onTagsUpdated: _handleTagsUpdated,
          );
        },
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE WIDGET
// ============================================================================

class _EmptyChatsView extends StatelessWidget {
  const _EmptyChatsView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 150),
        const CircleImageContainer(
          imagePath: 'assets/images/magnifier.png',
          size: 100,
        ),
        const SizedBox(height: 20),
        Text(
          'No conversations yet',
          style: GoogleFonts.roboto(
            fontSize: kFontSize20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Start chatting with agents about\nproperties you\'re interested in',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: kFontSize16,
            color: kGrey,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to explore properties
          },
          icon: const Icon(Icons.search, color: kWhite),
          label: Text(
            'Explore Properties',
            style: GoogleFonts.roboto(
              color: kWhite,
              fontSize: kFontSize14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: kPaddingH30V15,
            shape: RoundedRectangleBorder(
              borderRadius: kRadius30,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DISMISSIBLE CHAT ITEM WRAPPER
// ============================================================================

class _DismissibleChatItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onTagsUpdated;

  const _DismissibleChatItem({
    required this.chat,
    required this.onDelete,
    required this.onTap,
    required this.onTagsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(color: Colors.transparent),
      secondaryBackground: _buildDeleteBackground(),
      confirmDismiss: (direction) => _showDeleteConfirmation(context),
      onDismissed: (direction) => _handleDismiss(context),
      child: ChatListItem(
        chat: chat,
        onTagsUpdated: (_) => onTagsUpdated(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      color: kRed,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.delete_outline,
            color: kWhite,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            'Delete',
            style: GoogleFonts.roboto(
              color: kWhite,
              fontSize: kFontSize12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: Text(
            'Are you sure you want to delete this conversation with ${chat.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: kRed,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDismiss(BuildContext context) async {
    try {
      onDelete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }
}

// ============================================================================
// CHAT LIST ITEM
// ============================================================================

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final Function(List<String>) onTagsUpdated;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTagsUpdated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showTagBottomSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          color: chat.unreadCount > 0
              ? kPrimaryColor.withAlpha(8)
              : Colors.transparent,
          child: Row(
            children: [
              _ChatAvatar(chat: chat),
              const SizedBox(width: 16),
              Expanded(
                child: _ChatContent(chat: chat),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTagBottomSheet(BuildContext context) async {
    final updatedTags = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddTagBottomSheet(
          chatIdentifier: chat.otherParticipantId,
          currentTags: chat.tags,
        );
      },
    );
    if (updatedTags != null) {
      onTagsUpdated(updatedTags);
    }
  }
}

// ============================================================================
// CHAT AVATAR
// ============================================================================

class _ChatAvatar extends StatelessWidget {
  final Chat chat;

  const _ChatAvatar({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: chat.unreadCount > 0
                  ? kPrimaryColor.withAlpha(77)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundImage: _getAvatarImage(),
            backgroundColor: kPrimaryColor.withAlpha(26),
          ),
        ),
        if (chat.isOnline) _buildOnlineIndicator(),
      ],
    );
  }

  ImageProvider _getAvatarImage() {
    return getResolvedImageProvider(chat.imageUrl);
  }

  Widget _buildOnlineIndicator() {
    return Positioned(
      bottom: 2,
      right: 2,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: kGreen,
          shape: BoxShape.circle,
          border: Border.all(color: kWhite, width: 3),
        ),
      ),
    );
  }
}

// ============================================================================
// CHAT CONTENT
// ============================================================================

class _ChatContent extends StatelessWidget {
  final Chat chat;

  const _ChatContent({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 4),
        _buildMessageRow(),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            chat.name,
            style: GoogleFonts.roboto(
              fontWeight:
                  chat.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
              fontSize: kFontSize12,
              color: kPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          chat.time,
          style: GoogleFonts.roboto(
            fontSize: kFontSize10,
            color: chat.unreadCount > 0 ? kPrimaryColor : kGrey,
            fontWeight:
                chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            chat.message,
            style: GoogleFonts.roboto(
              fontSize: kFontSize12,
              color:
                  chat.unreadCount > 0 ? kPrimaryColor.withAlpha(204) : kGrey,
              fontWeight:
                  chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 8),
        _buildBadges(),
      ],
    );
  }

  Widget _buildBadges() {
    return Row(
      children: [
        if (chat.unreadCount > 0) _buildUnreadBadge(),
      ],
    );
  }

  Widget _buildUnreadBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: kRadius12,
      ),
      child: Text(
        chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
        style: GoogleFonts.roboto(
          color: kWhite,
          fontSize: kFontSize12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
