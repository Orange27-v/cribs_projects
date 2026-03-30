import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_arena/screens/review/report_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:cribs_arena/services/chat_service.dart'; // Import ChatService
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:cribs_arena/screens/chat/location_picker_screen.dart'; // Import LocationPickerScreen
import 'package:latlong2/latlong.dart'; // Import LatLng
import 'package:cribs_arena/services/socket_service.dart'; // Import SocketService
import 'package:cribs_arena/widgets/widgets.dart'; // Import PrimaryAppBar
import 'package:google_maps_flutter/google_maps_flutter.dart'
    as gmaps; // For embedded map
import 'package:cribs_arena/screens/property/property_details_screen.dart';
import 'package:cribs_arena/screens/schedule/schedule_screen.dart'; // Import MyScheduleScreen

//----------- DATA MODELS -----------

// Represents a single message in a conversation
enum MessageSender { user, other } // Changed from agent to other

enum MessageType { text, location, property }

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final String time;
  final String? imageUrl; // For special card messages
  final String? cardTitle; // For special card messages
  final IconData? cardIcon; // For special card messages
  final MessageType messageType;
  final PropertyMessageData? propertyData;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    this.imageUrl,
    this.cardTitle,
    this.cardIcon,
    this.messageType = MessageType.text,
    this.propertyData,
  });

  factory Message.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Try multiple possible field names for sender ID
    final senderId = (json['senderId'] ??
                json['fromId'] ??
                json['sender_id'] ??
                json['from_id'])
            ?.toString() ??
        '';

    // Strictly enforce: if senderId matches currentUserId, it's a sent message
    final isCurrentUser = senderId.isNotEmpty && senderId == currentUserId;

    final bool isCardMessage = json['type'] == 'card';
    final String? imageUrl = isCardMessage ? json['image_url'] : null;
    final String? cardTitle = isCardMessage ? json['card_title'] : null;
    final IconData? cardIcon =
        isCardMessage ? Icons.info_outline : null; // Example icon

    // Determine message type
    MessageType msgType = MessageType.text;
    PropertyMessageData? propData;

    final rawMessageType = json['messageType']?.toString();
    if (rawMessageType == 'property' && json['propertyData'] != null) {
      msgType = MessageType.property;
      dynamic pData = json['propertyData'];
      // If the backend didn't parse the JSON string, do it here
      if (pData is String) {
        try {
          pData = jsonDecode(pData);
        } catch (e) {
          debugPrint('Error decoding propertyData string: $e');
        }
      }
      if (pData is Map<String, dynamic>) {
        propData = PropertyMessageData.fromJson(pData);
      }
    } else if (rawMessageType == 'location') {
      msgType = MessageType.location;
    }

    debugPrint('DEBUG: Raw Message Type: $rawMessageType');
    if (rawMessageType == 'property') {
      debugPrint('DEBUG: Property Data in JSON: ${json['propertyData']}');
    }

    return Message(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          DateTime.now().toString(),
      text: json['text'] as String? ?? '',
      sender: isCurrentUser ? MessageSender.user : MessageSender.other,
      time: _formatTime(json['timestamp'] as String?),
      imageUrl: imageUrl,
      cardTitle: cardTitle,
      cardIcon: cardIcon,
      messageType: msgType,
      propertyData: propData,
    );
  }

  static String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    final dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat.jm().format(dateTime); // e.g., 9:32 AM
  }
}

// Property data for property messages
class PropertyMessageData {
  final String propertyId;
  final String title;
  final String type;
  final String location;
  final double price;
  final int beds;
  final int baths;
  final List<String> images; // Changed to list for carousel
  final String listingType;

  PropertyMessageData({
    required this.propertyId,
    required this.title,
    required this.type,
    required this.location,
    required this.price,
    required this.beds,
    required this.baths,
    required this.images,
    required this.listingType,
  });

  factory PropertyMessageData.fromJson(Map<String, dynamic> json) {
    // Handle both single image and images array
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['image'] != null) {
      // Backward compatibility with single image
      imagesList = [json['image'].toString()];
    }

    return PropertyMessageData(
      propertyId: (json['id'] ?? json['propertyId'] ?? json['property_id'])
              ?.toString() ??
          '',
      title: (json['title'] ?? json['name'])?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      beds: (json['beds'] is num) ? (json['beds'] as num).toInt() : 0,
      baths: (json['baths'] is num) ? (json['baths'] as num).toInt() : 0,
      images: imagesList,
      listingType:
          (json['listingType'] ?? json['listing_type'])?.toString() ?? '',
    );
  }
}

//----------- CONVERSATION SCREEN -----------

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherParticipantId;
  final String agentName;
  final String agentImageUrl;
  final String? initialMessage; // Added for preloading messages
  final Map<String, dynamic>? initialPropertyData; // Property data for card

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherParticipantId,
    required this.agentName,
    required this.agentImageUrl,
    this.initialMessage, // Optional initial message
    this.initialPropertyData, // Optional property data for property card
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  String? _currentUserId;

  // Selection mode for deleting messages
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  // Property card display
  // Removed _showPropertyCard and _propertyCardData

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rawUserId = userProvider.user?['user_id'].toString();

    if (rawUserId == null) return;

    // Add user_ prefix to match MongoDB format
    _currentUserId = 'user_$rawUserId';

    // Connect socket if not already connected
    if (!SocketService.isConnected()) {
      SocketService.connect(_currentUserId!);
    }

    // Mark the conversion as read
    _chatService.markAsRead(widget.conversationId, _currentUserId!);

    // Refresh messages ensures we have the latest
    _chatService.refreshMessages(widget.conversationId);

    // Auto-send property card message
    debugPrint(
        'DEBUG: Init Conversation. Initial Property Data: ${widget.initialPropertyData}');
    _sendInitialPropertyMessage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatService.clearActiveConversation(); // Clear active conversation state
    super.dispose();
  }

  void _sendInitialPropertyMessage() {
    if (widget.initialPropertyData != null && _currentUserId != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final propertyMessageData = {
          'conversationId': widget.conversationId,
          'fromId': _currentUserId,
          'toId': widget.otherParticipantId,
          'text': 'Shared a property',
          'messageType': 'property',
          'propertyData': jsonEncode(widget.initialPropertyData),
        };
        debugPrint(
            'DEBUG: Sending Initial Property Message: $propertyMessageData');
        SocketService.sendMessage(propertyMessageData);
      });
    }
  }

  // Function to send a message using SocketService
  void _sendMessage(String text) {
    if (text.trim().isEmpty || _currentUserId == null) return;

    final messageData = {
      'conversationId': widget.conversationId,
      'fromId': _currentUserId,
      'toId': widget.otherParticipantId,
      'text': text,
    };

    SocketService.sendMessage(messageData);
    // The stream will update automatically when the socket event comes back

    _scrollToBottom();
  }

  void _sendLocationMessage(LatLng location) {
    // Note: This needs backend support for location messages types
    // For now we send as text
    _sendMessage('Location: ${location.latitude}, ${location.longitude}');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: kDuration300ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMessageIds.clear();
      }
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: const Text('Delete Messages'),
        content: Text('Delete ${_selectedMessageIds.length} message(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messageIdsToDelete = _selectedMessageIds.toList();

      setState(() {
        _toggleSelectionMode(); // Exit selection mode
      });

      try {
        await _chatService.deleteMessages(
          widget.conversationId,
          messageIdsToDelete,
        );
        // Service will automatically refresh the stream
      } catch (e) {
        debugPrint('Error deleting messages: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete messages: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Property card header (shown when user comes from property details)

          Expanded(
            child: _currentUserId == null
                ? const Center(child: CustomLoadingIndicator())
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream:
                        _chatService.getMessagesStream(widget.conversationId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CustomLoadingIndicator());
                      } else if (snapshot.hasError) {
                        return NetworkErrorWidget(
                          errorMessage: getErrorMessage(snapshot.error),
                          title: 'Unable to Load Messages',
                          icon: Icons.chat_bubble_outline,
                          onRefresh: () {
                            _chatService.refreshMessages(widget.conversationId);
                          },
                        );
                      }

                      final rawMessages = snapshot.data ?? [];
                      if (rawMessages.isEmpty) {
                        // If we have an initial message passed (e.g. from property details), show it
                        // This is tricky because it's not in the stream yet.
                        // But usually initiation creates conversation and effectively sends message?
                        // If just UI, maybe we should display it.
                        if (widget.initialMessage != null) {
                          // Check if it was sent? No, the widget expects us to potentially send it.
                          // Actually logic in _MessageInputField uses initialMessage to pre-fill text.
                          return const Center(child: Text('No messages yet.'));
                        }
                        return const Center(child: Text('No messages yet.'));
                      }

                      // Parse and sort
                      final messages = rawMessages
                          .map((json) {
                            try {
                              return Message.fromJson(json, _currentUserId!);
                            } catch (e) {
                              debugPrint('Error parsing message: $e');
                              return null;
                            }
                          })
                          .whereType<Message>()
                          .toList()
                          .reversed
                          .toList();

                      return ListView.builder(
                        controller: _scrollController,
                        padding: kPaddingH16V8,
                        reverse: true, // To show latest messages at the bottom
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _MessageItem(
                            message: message,
                            isSelectionMode: _isSelectionMode,
                            isSelected:
                                _selectedMessageIds.contains(message.id),
                            onLongPress: () => _toggleSelectionMode(),
                            onTap: _isSelectionMode
                                ? () => _toggleMessageSelection(message.id)
                                : null,
                            onBookInspection: (propertyData) =>
                                _handleBookInspection(context, propertyData),
                            onViewProperty: (propertyData) =>
                                _handleViewProperty(context, propertyData),
                          );
                        },
                      );
                    },
                  ),
          ),
          _MessageInputField(
            onSendMessage: _sendMessage,
            agentName: widget.agentName,
            otherParticipantId: widget.otherParticipantId,
            onSendLocation: _sendLocationMessage,
            initialMessage: widget.initialMessage,
          ),
        ],
      ),
    );
  }

  void _handleBookInspection(
      BuildContext context, PropertyMessageData propertyData) {
    // Navigate to MyScheduleScreen as requested
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyScheduleScreen(),
      ),
    );
  }

  void _handleViewProperty(
      BuildContext context, PropertyMessageData propertyData) {
    debugPrint(
        'DEBUG: _handleViewProperty called with ID: ${propertyData.propertyId}');

    if (propertyData.propertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid property ID')),
      );
      return;
    }

    // Navigate to PropertyDetailsScreen with the property ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsScreen(
          propertyId: propertyData.propertyId,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Selection mode AppBar
    if (_isSelectionMode) {
      return PrimaryAppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _toggleSelectionMode,
        ),
        title: Text('${_selectedMessageIds.length} selected'),
        actions: [
          if (_selectedMessageIds.isNotEmpty)
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/trash-pattern.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  kPrimaryColor,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: _deleteSelectedMessages,
              tooltip: 'Delete selected messages',
            ),
          const SizedBox(width: kSizedBoxW8),
        ],
      );
    }

    // Normal AppBar
    return PrimaryAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: kFontSize20,
            backgroundImage: widget.agentImageUrl.isNotEmpty
                ? NetworkImage(widget.agentImageUrl.startsWith('http')
                    ? widget.agentImageUrl
                    : '$kMainBaseUrl${widget.agentImageUrl.startsWith('/') ? widget.agentImageUrl.substring(1) : widget.agentImageUrl}')
                : const AssetImage('assets/images/default_profile.jpg')
                    as ImageProvider,
            backgroundColor: kGrey.withAlpha(51),
          ),
          const SizedBox(width: kSizedBoxW12),
          Expanded(
            child: Text(
              widget.agentName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/flag.svg',
            colorFilter: const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
            height: kIconSize20,
            width: kIconSize20,
          ),
          onPressed: () {
            // Extract numeric ID from format "agent_123" or "user_123"
            final numericId = widget.otherParticipantId
                .replaceAll('agent_', '')
                .replaceAll('user_', '');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportScreen(agentId: numericId),
              ),
            );
          },
        ),
        const SizedBox(width: kSizedBoxW8), // Add some spacing
      ],
    );
  }
}

//----------- MESSAGE WIDGETS -----------

// Chooses which message widget to display
class _MessageItem extends StatelessWidget {
  final Message message;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final Function(PropertyMessageData)? onBookInspection;
  final Function(PropertyMessageData)? onViewProperty;

  const _MessageItem({
    required this.message,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.onBookInspection,
    this.onViewProperty,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: kPaddingV3,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Selection checkbox (always on the left)
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : kGrey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: isSelected ? kPrimaryColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: kWhite,
                          size: 16,
                        )
                      : null,
                ),
              ),
            // Message content
            Expanded(
              child: Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: _buildMessageContent(message, isUser),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isUser) {
    // Check message type first
    if (message.messageType == MessageType.property &&
        message.propertyData != null) {
      return _PropertyMessageBubble(
        message: message,
        isUser: isUser,
        showBookButton: true, // User view - show book button
        onBookInspection: onBookInspection != null
            ? () => onBookInspection!(message.propertyData!)
            : null,
        onViewProperty: onViewProperty != null
            ? () => onViewProperty!(message.propertyData!)
            : null,
      );
    }

    if (message.imageUrl != null) {
      return _SpecialMessageCard(message: message, isUser: isUser);
    }

    if (_isLocationMessage(message.text)) {
      return _LocationMessageBubble(message: message, isUser: isUser);
    }

    return _TextMessageBubble(message: message, isUser: isUser);
  }

  // Helper to detect location messages
  static bool _isLocationMessage(String text) {
    return text.startsWith('Location:') &&
        RegExp(r'Location:\s*-?\d+\.\d+,\s*-?\d+\.\d+').hasMatch(text);
  }
}

// Displays a standard text message with modern chat bubble styling
class _TextMessageBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  const _TextMessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Sent messages = primary gradient, received = light subtle color
            gradient: isUser
                ? const LinearGradient(
                    colors: [kPrimaryColor, Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : const Color(0xFFE8F4FD),
            // Asymmetric border radius for chat bubble tail effect
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isUser ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight:
                  isUser ? const Radius.circular(4) : const Radius.circular(18),
            ),
            // Subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color:
                    isUser ? kPrimaryColor.withAlpha(40) : kBlack.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: RichText(
            text: TextSpan(
              children: _buildTextSpans(message.text, context, isUser),
            ),
          ),
        ),
        // Time stamp below the bubble
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: isUser ? 0 : 4,
            right: isUser ? 4 : 0,
          ),
          child: Text(
            message.time,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: kGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildTextSpans(
      String text, BuildContext context, bool isUser) {
    final List<TextSpan> spans = [];
    final RegExp urlRegex = RegExp(
      r'(https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://[a-zA-Z0-9]+\.[^\s]{2,}|[a-zA-Z0-9]+\.[^\s]{2,})',
      caseSensitive: false,
    );

    text.splitMapJoin(
      urlRegex,
      onMatch: (Match match) {
        final String url = match.group(0)!;
        spans.add(
          TextSpan(
            text: url,
            style: GoogleFonts.roboto(
              color: isUser ? Colors.blue.shade200 : Colors.blue.shade700,
              fontSize: kFontSize12,
              height: 1.4,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Could not launch $url')),
                  );
                }
              },
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(
          TextSpan(
            text: nonMatch,
            style: GoogleFonts.roboto(
              color: isUser ? kWhite : kBlack87,
              fontSize: kFontSize12,
              height: 1.4,
            ),
          ),
        );
        return '';
      },
    );
    return spans;
  }
}

// Displays a location message with an interactive map preview
class _LocationMessageBubble extends StatelessWidget {
  final Message message;
  final bool isUser;
  const _LocationMessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // Parse location from message text
    final coords = _parseLocation(message.text);
    if (coords == null) {
      return _TextMessageBubble(message: message, isUser: isUser);
    }

    final latitude = coords['lat']!;
    final longitude = coords['lon']!;

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openInMaps(latitude, longitude),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? kPrimaryColor.withAlpha(40)
                      : kBlack.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Map Preview using embedded GoogleMap
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: kGrey100,
                    ),
                    child: IgnorePointer(
                      // Prevent map interaction - tap goes to _openInMaps
                      child: gmaps.GoogleMap(
                        initialCameraPosition: gmaps.CameraPosition(
                          target: gmaps.LatLng(latitude, longitude),
                          zoom: 15,
                        ),
                        markers: {
                          gmaps.Marker(
                            markerId: const gmaps.MarkerId('location'),
                            position: gmaps.LatLng(latitude, longitude),
                            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                              gmaps.BitmapDescriptor.hueRed,
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        liteModeEnabled:
                            true, // Use lite mode for better performance in list
                      ),
                    ),
                  ),
                  // Location info footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    color: isUser ? kPrimaryColor : const Color(0xFFE8F4FD),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isUser ? kWhite : kPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shared Location',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isUser ? kWhite : kBlack87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: isUser ? kWhite.withAlpha(180) : kGrey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Time stamp
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: isUser ? 0 : 4,
            right: isUser ? 4 : 0,
          ),
          child: Text(
            message.time,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: kGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, double>? _parseLocation(String text) {
    final match =
        RegExp(r'Location:\s*(-?\d+\.\d+),\s*(-?\d+\.\d+)').firstMatch(text);
    if (match != null) {
      return {
        'lat': double.parse(match.group(1)!),
        'lon': double.parse(match.group(2)!),
      };
    }
    return null;
  }

  Future<void> _openInMaps(double lat, double lon) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// Displays a property message with card preview and book button for users
class _PropertyMessageBubble extends StatefulWidget {
  final Message message;
  final bool isUser;
  final bool showBookButton;
  final VoidCallback? onBookInspection;
  final VoidCallback? onViewProperty;

  const _PropertyMessageBubble({
    required this.message,
    required this.isUser,
    this.showBookButton = false,
    this.onBookInspection,
    this.onViewProperty,
  });

  @override
  State<_PropertyMessageBubble> createState() => _PropertyMessageBubbleState();
}

class _PropertyMessageBubbleState extends State<_PropertyMessageBubble> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertyData = widget.message.propertyData!;
    final hasImages = propertyData.images.isNotEmpty;
    final hasMultipleImages = propertyData.images.length > 1;

    // Determine if this is a user-sent (viewing property) or agent-sent (schedule inspection)
    final isFromUser = widget.isUser;

    return Column(
      crossAxisAlignment:
          isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kBlack.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main content area (tappable for "View")
                  InkWell(
                    onTap: widget.onViewProperty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Property image with centered icon overlay
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Image carousel or single image
                            SizedBox(
                              height: 180,
                              child: hasImages
                                  ? PageView.builder(
                                      controller: _pageController,
                                      itemCount: propertyData.images.length,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        return Image.network(
                                          propertyData.images[index],
                                          width: double.infinity,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              color: kGrey100,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                  color: kPrimaryColor,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: kGrey100,
                                            child: Center(
                                              child: Icon(Icons.home,
                                                  size: 50,
                                                  color: kGrey.withAlpha(100)),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: kGrey100,
                                      child: Center(
                                        child: Icon(Icons.home,
                                            size: 50,
                                            color: kGrey.withAlpha(100)),
                                      ),
                                    ),
                            ),
                            // Centered icon overlay (eye for user, calendar for agent)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kWhite,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: kBlack.withAlpha(20),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFromUser
                                    ? Icons.visibility_outlined
                                    : Icons.calendar_today_outlined,
                                color: kPrimaryColor,
                                size: 28,
                              ),
                            ),
                            // Image counter for multiple images
                            if (hasMultipleImages)
                              Positioned(
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: kBlack.withAlpha(120),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentImageIndex + 1} / ${propertyData.images.length}',
                                    style: GoogleFonts.roboto(
                                      color: kWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Title section with blue/light blue background
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isFromUser ? kPrimaryColor : kLightBlue,
                          ),
                          child: Text(
                            '${propertyData.beds} Bedroom ${propertyData.type}, ${propertyData.location.split(',').first}',
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isFromUser ? kWhite : kPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons row (not inside content InkWell to avoid nested taps)
                  Container(
                    decoration: BoxDecoration(
                      color: isFromUser
                          ? kPrimaryColor.withAlpha(20)
                          : kLightBlue.withAlpha(100),
                      border: Border(
                        top: BorderSide(color: kGrey.withAlpha(30)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.visibility_outlined,
                            label: 'View Property',
                            onTap: widget.onViewProperty,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: kGrey.withAlpha(50),
                        ),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.calendar_month_outlined,
                            label: 'Schedule',
                            onTap: widget.onBookInspection,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Time stamp
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: isFromUser ? 0 : 4,
            right: isFromUser ? 4 : 0,
          ),
          child: Text(
            widget.message.time,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: kGrey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// Bottom sheet for booking inspection
class _BookInspectionSheet extends StatefulWidget {
  final PropertyMessageData propertyData;

  const _BookInspectionSheet({required this.propertyData});

  @override
  State<_BookInspectionSheet> createState() => _BookInspectionSheetState();
}

class _BookInspectionSheetState extends State<_BookInspectionSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _submitBooking() {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: Implement actual booking API call
    // For now, simulate a booking request
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Inspection booking requested for ${widget.propertyData.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kGrey400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.orange.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Inspection',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kBlack87,
                        ),
                      ),
                      Text(
                        widget.propertyData.title,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: kGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date picker
                  Text(
                    'Select Date',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kBlack87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: kGrey.withAlpha(60)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: kPrimaryColor),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? DateFormat('EEEE, MMM d, yyyy')
                                    .format(_selectedDate!)
                                : 'Choose a date',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: _selectedDate != null ? kBlack87 : kGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Time picker
                  Text(
                    'Select Time',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kBlack87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: kGrey.withAlpha(60)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: kPrimaryColor),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Choose a time',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: _selectedTime != null ? kBlack87 : kGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Notes (optional)
                  Text(
                    'Additional Notes (optional)',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kBlack87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any special requests or questions...',
                      hintStyle: GoogleFonts.roboto(color: kGrey, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kGrey.withAlpha(60)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kGrey.withAlpha(60)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kWhite,
                            ),
                          )
                        : Text(
                            'Request Inspection',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Displays a special message with an image card and an optional text bubble
class _SpecialMessageCard extends StatelessWidget {
  final Message message;
  final bool isUser;
  const _SpecialMessageCard({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // The image card part
          Container(
            decoration: BoxDecoration(
              borderRadius: kRadius8,
              boxShadow: [
                BoxShadow(
                  color: kBlack.withAlpha(26),
                  spreadRadius: 1,
                  blurRadius: kBlurRadius8,
                  offset: kOffset02,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: kRadius8,
              child: Stack(
                children: [
                  // Property image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: kGrey.withAlpha(77),
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: kGrey, size: kFontSize40),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            kBlack.withAlpha(153),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Property title with icon
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: kPaddingH12V8,
                      decoration: BoxDecoration(
                        color: kBlack.withAlpha(18),
                        borderRadius: kRadius8,
                      ),
                      child: Row(
                        children: [
                          Icon(message.cardIcon!,
                              color: kWhite, size: kFontSize18),
                          const SizedBox(width: kSizedBoxW8),
                          Expanded(
                            child: Text(
                              message.cardTitle!,
                              style: GoogleFonts.roboto(
                                color: kWhite,
                                fontSize: kFontSize14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Eye icon indicator (top right)
                  if (message.cardIcon == Icons.visibility_outlined)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: kPaddingAll6,
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.visibility,
                            color: kWhite, size: kFontSize16),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // The text bubble part below the card (if text exists)
          if (message.text.isNotEmpty)
            Padding(
              padding: kPaddingOnlyTop6,
              child: _TextMessageBubble(message: message, isUser: isUser),
            ),
        ],
      ),
    );
  }
}

// The message input field at the bottom
class _MessageInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final String agentName;
  final String otherParticipantId;
  final Function(LatLng) onSendLocation;
  final String? initialMessage; // Added for preloading

  const _MessageInputField({
    required this.onSendMessage,
    required this.agentName,
    required this.otherParticipantId,
    required this.onSendLocation,
    this.initialMessage, // Optional initial message
  });

  @override
  State<_MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<_MessageInputField> {
  final _textController = TextEditingController();
  // Removed bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Preload initial message if provided
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _textController.text = widget.initialMessage!;
    }
  }

  // Removed void _updateTypingStatus()

  void _handleSend() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onSendMessage(_textController.text.trim());
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: kFontSize16,
        right: kFontSize16,
        top: kFontSize12,
        bottom: MediaQuery.of(context).padding.bottom + kFontSize12,
      ),
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: kGrey.withAlpha(38),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom
        children: [
          GestureDetector(
            onTap: () async {
              final LatLng? pickedLocation = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationPickerScreen(),
                ),
              );
              if (pickedLocation != null) {
                widget.onSendLocation(pickedLocation);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: kWhite,
                size: kIconSize20,
              ),
            ),
          ),
          const SizedBox(width: kSizedBoxW12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kGrey100, // A light background for the input area
                borderRadius:
                    kRadius12, // Rounded corners for rectangular shape
              ),
              padding: kPaddingH12V8, // Padding inside the input area
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Reply to ${widget.agentName}',
                  border: InputBorder.none, // Remove default TextField border
                  hintStyle:
                      GoogleFonts.roboto(color: kGrey, fontSize: kFontSize10),
                  isDense: true, // Reduce vertical space
                  contentPadding:
                      EdgeInsets.zero, // Remove default content padding
                ),
                maxLines: null, // Allows the TextField to grow vertically
                minLines: 1, // Starts as a single line
                keyboardType: TextInputType
                    .multiline, // Optimizes keyboard for multiline input
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: kSizedBoxW12),
          // Always show the send button
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: kWhite,
                size: kIconSize20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Action button for property card
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: kPrimaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
