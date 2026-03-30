import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/screens/review/report_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:cribs_agents/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:cribs_agents/provider/agent_provider.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/screens/chat/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:cribs_agents/services/socket_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/property_service.dart';
import 'package:cribs_agents/models/property.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart'
    as gmaps; // For embedded map
import 'package:cribs_agents/screens/chat/widgets/property_picker_sheet.dart';
import 'package:cribs_agents/screens/schedule/schedule_screen.dart';
import 'package:cribs_agents/screens/properties/properties_screen.dart';

//----------- DATA MODELS -----------

enum MessageSender {
  me,
  other
} // Changed from user/other to me/other for clarity in agent context

enum MessageType { text, location, property }

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final String time;
  final String? imageUrl;
  final String? cardTitle;
  final IconData? cardIcon;
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
    final senderId = (json['senderId'] ??
                json['fromId'] ??
                json['sender_id'] ??
                json['from_id'])
            ?.toString() ??
        '';

    final isCurrentUser = senderId.isNotEmpty && senderId == currentUserId;

    final bool isCardMessage = json['type'] == 'card';
    final String? imageUrl = isCardMessage ? json['image_url'] : null;
    final String? cardTitle = isCardMessage ? json['card_title'] : null;
    final IconData? cardIcon = isCardMessage ? Icons.info_outline : null;

    // Determine message type
    MessageType msgType = MessageType.text;
    PropertyMessageData? propData;

    final rawMessageType = json['messageType']?.toString();
    if (rawMessageType == 'property' && json['propertyData'] != null) {
      msgType = MessageType.property;
      propData = PropertyMessageData.fromJson(json['propertyData']);
    } else if (rawMessageType == 'location') {
      msgType = MessageType.location;
    }

    return Message(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          DateTime.now().toString(),
      text: json['text'] as String? ?? '',
      sender: isCurrentUser ? MessageSender.me : MessageSender.other,
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
    return DateFormat.jm().format(dateTime);
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
      propertyId: (json['id'] ?? json['propertyId'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      beds: (json['beds'] is num) ? (json['beds'] as num).toInt() : 0,
      baths: (json['baths'] is num) ? (json['baths'] as num).toInt() : 0,
      images: imagesList,
      listingType: json['listingType']?.toString() ?? '',
    );
  }
}

//----------- CONVERSATION SCREEN -----------

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherParticipantId;
  final String participantName; // The User's name
  final String participantImageUrl; // The User's avatar
  final String? initialMessage;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherParticipantId,
    required this.participantName,
    required this.participantImageUrl,
    this.initialMessage,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  String? _currentUserId;

  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final rawUserId = agentProvider.agent?.agentId.toString();

    if (rawUserId == null) return;

    _currentUserId = 'agent_$rawUserId';

    if (!SocketService.isConnected()) {
      SocketService.connect(_currentUserId!);
    }

    _chatService.markAsRead(widget.conversationId, _currentUserId!);
    _chatService.refreshMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatService.clearActiveConversation(); // Clear active conversation state
    super.dispose();
  }

  ImageProvider _getProfileImage(String? path) {
    return getResolvedImageProvider(path);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _currentUserId == null) return;

    final messageData = {
      'conversationId': widget.conversationId,
      'fromId': _currentUserId,
      'toId': widget.otherParticipantId,
      'text': text,
    };

    SocketService.sendMessage(messageData);
    _scrollToBottom();
  }

  void _sendLocationMessage(LatLng location) {
    _sendMessage('Location: ${location.latitude}, ${location.longitude}');
  }

  // Send a property message
  void _sendPropertyMessage(Property property) {
    if (_currentUserId == null) return;

    final propertyData = {
      'id': property.id,
      'propertyId': property.propertyId,
      'title': property.title,
      'type': property.type,
      'location': property.location,
      'price': property.price,
      'beds': property.beds,
      'baths': property.baths,
      'images': property.images ?? [], // Send all images for carousel
      'image': (property.images != null && property.images!.isNotEmpty)
          ? property.images![0]
          : null,
      'listingType': property.listingType,
    };

    final messageData = {
      'conversationId': widget.conversationId,
      'fromId': _currentUserId,
      'toId': widget.otherParticipantId,
      'text': '🏠 ${property.title} - ${property.location}',
      'messageType': 'property',
      'propertyData': jsonEncode(propertyData), // convert Map to JSON string
    };

    SocketService.sendMessage(messageData);
    _scrollToBottom();
  }

  // Handle view property action from property card - navigates to PropertiesScreen
  void _handleViewProperty(PropertyMessageData propertyData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PropertiesScreen(),
      ),
    );
  }

  // Handle view bookings action from property card
  void _handleViewBookings(PropertyMessageData propertyData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyScheduleScreen(),
      ),
    );
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
      builder: (context) => AlertDialog(
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
        _toggleSelectionMode();
      });

      try {
        await _chatService.deleteMessages(
          widget.conversationId,
          messageIdsToDelete,
        );
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
                        if (widget.initialMessage != null) {
                          return const Center(child: Text('No messages yet.'));
                        }
                        return const Center(child: Text('No messages yet.'));
                      }

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
                        reverse: true,
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
                            onViewProperty: _handleViewProperty,
                            onViewBookings: _handleViewBookings,
                          );
                        },
                      );
                    },
                  ),
          ),
          _MessageInputField(
            onSendMessage: _sendMessage,
            participantName: widget.participantName,
            otherParticipantId: widget.otherParticipantId,
            onSendLocation: _sendLocationMessage,
            onSendProperty: _sendPropertyMessage,
            initialMessage: widget.initialMessage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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

    return PrimaryAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: kFontSize20,
            backgroundImage: _getProfileImage(widget.participantImageUrl),
            backgroundColor: kGrey.withAlpha(51),
          ),
          const SizedBox(width: kSizedBoxW12),
          Expanded(
            child: Text(
              widget.participantName,
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: kSizedBoxW8),
      ],
    );
  }
}

//----------- MESSAGE WIDGETS -----------

class _MessageItem extends StatelessWidget {
  final Message message;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final Function(PropertyMessageData)? onViewProperty;
  final Function(PropertyMessageData)? onViewBookings;

  const _MessageItem({
    required this.message,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.onViewProperty,
    this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.sender == MessageSender.me;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: kPaddingV3,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: _buildMessageContent(message, isMe),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isMe) {
    // Check message type first
    if (message.messageType == MessageType.property &&
        message.propertyData != null) {
      return _PropertyMessageBubble(
        message: message,
        isMe: isMe,
        showBookButton: false, // Agent view - no book button
        onViewProperty: onViewProperty != null
            ? () => onViewProperty!(message.propertyData!)
            : null,
        onViewBookings: onViewBookings != null
            ? () => onViewBookings!(message.propertyData!)
            : null,
      );
    }

    if (message.imageUrl != null) {
      return _SpecialMessageCard(message: message, isMe: isMe);
    }

    if (_isLocationMessage(message.text)) {
      return _LocationMessageBubble(message: message, isMe: isMe);
    }

    return _TextMessageBubble(message: message, isMe: isMe);
  }

  // Helper to detect location messages
  static bool _isLocationMessage(String text) {
    return text.startsWith('Location:') &&
        RegExp(r'Location:\s*-?\d+\.\d+,\s*-?\d+\.\d+').hasMatch(text);
  }
}

class _TextMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  const _TextMessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Sent messages = primary gradient, received = light subtle color
            gradient: isMe
                ? const LinearGradient(
                    colors: [kPrimaryColor, Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isMe ? null : const Color(0xFFE8F4FD),
            // Asymmetric border radius for chat bubble tail effect
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isMe ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight:
                  isMe ? const Radius.circular(4) : const Radius.circular(18),
            ),
            // Subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color:
                    isMe ? kPrimaryColor.withAlpha(40) : kBlack.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: RichText(
            text: TextSpan(
              children: _buildTextSpans(message.text, context, isMe),
            ),
          ),
        ),
        // Time stamp below the bubble
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: isMe ? 0 : 4,
            right: isMe ? 4 : 0,
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

  List<TextSpan> _buildTextSpans(String text, BuildContext context, bool isMe) {
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
              color: isMe ? Colors.blue.shade200 : Colors.blue.shade700,
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
              color: isMe ? kWhite : kBlack87,
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
  final bool isMe;
  const _LocationMessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Parse location from message text
    final coords = _parseLocation(message.text);
    if (coords == null) {
      return _TextMessageBubble(message: message, isMe: isMe);
    }

    final latitude = coords['lat']!;
    final longitude = coords['lon']!;

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                bottomLeft:
                    isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight:
                    isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isMe ? kPrimaryColor.withAlpha(40) : kBlack.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight:
                    isMe ? const Radius.circular(4) : const Radius.circular(18),
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
                    color: isMe ? kPrimaryColor : const Color(0xFFE8F4FD),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isMe ? kWhite : kPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shared Location',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isMe ? kWhite : kBlack87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: isMe ? kWhite.withAlpha(180) : kGrey,
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
            left: isMe ? 0 : 4,
            right: isMe ? 4 : 0,
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

// Displays a property message with card preview
class _PropertyMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showBookButton;
  final VoidCallback? onViewProperty;
  final VoidCallback? onViewBookings;

  const _PropertyMessageBubble({
    required this.message,
    required this.isMe,
    this.showBookButton = false,
    this.onViewProperty,
    this.onViewBookings,
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

    // In cribs_agents:
    // isMe = true (Agent sent it) -> Should look like Agent Card (Light Blue Title)
    // isMe = false (User sent it) -> Should look like User Card (Blue Title)
    final isAgentCard = widget.isMe;

    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onViewProperty,
          child: Container(
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
                                    getResolvedImageUrl(
                                        propertyData.images[index],
                                        isProperty: true),
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: kGrey100,
                                        child: Center(
                                          child: CircularProgressIndicator(
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
                                    errorBuilder: (_, __, ___) => Container(
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
                                      size: 50, color: kGrey.withAlpha(100)),
                                ),
                              ),
                      ),
                      // Centered icon overlay
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
                          isAgentCard
                              ? Icons.calendar_today_outlined
                              : Icons.visibility_outlined,
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
                  // Title section
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isAgentCard ? kLightBlue : kPrimaryColor,
                    ),
                    child: Text(
                      '${propertyData.beds} Bedroom ${propertyData.type}, ${propertyData.location.split(',').first}',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isAgentCard ? kPrimaryColor : kWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Agent action buttons (View Property, View Bookings)
                  if (widget.isMe)
                    Container(
                      decoration: BoxDecoration(
                        color: kLightBlue.withAlpha(100),
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
                              label: 'Bookings',
                              onTap: widget.onViewBookings,
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
            left: widget.isMe ? 0 : 4,
            right: widget.isMe ? 4 : 0,
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

class _SpecialMessageCard extends StatelessWidget {
  final Message message;
  final bool isMe;
  const _SpecialMessageCard({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
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
          if (message.text.isNotEmpty)
            Padding(
              padding: kPaddingOnlyTop6,
              child: _TextMessageBubble(message: message, isMe: isMe),
            ),
        ],
      ),
    );
  }
}

class _MessageInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final String participantName;
  final String otherParticipantId;
  final Function(LatLng) onSendLocation;
  final Function(Property) onSendProperty;
  final String? initialMessage;

  const _MessageInputField({
    required this.onSendMessage,
    required this.participantName,
    required this.otherParticipantId,
    required this.onSendLocation,
    required this.onSendProperty,
    this.initialMessage,
  });

  @override
  State<_MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<_MessageInputField> {
  final _textController = TextEditingController();
  final PropertyService _propertyService = PropertyService();

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _textController.text = widget.initialMessage!;
    }
  }

  void _handleSend() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onSendMessage(_textController.text.trim());
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  // Show property picker bottom sheet
  void _showPropertyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PropertyPickerSheet(
        propertyService: _propertyService,
        onPropertySelected: (property) {
          Navigator.pop(context);
          widget.onSendProperty(property);
        },
      ),
    );
  }

  // Show attachment options bottom sheet
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kGrey400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Share with client',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kBlack87,
                  ),
                ),
                const SizedBox(height: 20),
                // Options row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Location option
                    _AttachmentOption(
                      icon: Icons.location_on,
                      label: 'Location',
                      color: kPrimaryColor,
                      onTap: () async {
                        Navigator.pop(context);
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
                    ),
                    // Property option
                    _AttachmentOption(
                      icon: Icons.home_work_outlined,
                      label: 'Property',
                      color: Colors.orange.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        _showPropertyPicker();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button (opens bottom sheet with location + property options)
          GestureDetector(
            onTap: _showAttachmentOptions,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: kWhite,
                size: kIconSize20,
              ),
            ),
          ),
          const SizedBox(width: kSizedBoxW12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kGrey100,
                borderRadius: kRadius12,
              ),
              padding: kPaddingH12V8,
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.roboto(
                  fontSize: kFontSize14,
                  color: kBlack87,
                ),
                decoration: InputDecoration(
                  hintText: kTypeAMessageText,
                  hintStyle: GoogleFonts.roboto(
                    color: kGrey,
                    fontSize: kFontSize14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: kSizedBoxW12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
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

// Attachment option button for the share modal
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: kWhite,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kBlack87,
            ),
          ),
        ],
      ),
    );
  }
}
