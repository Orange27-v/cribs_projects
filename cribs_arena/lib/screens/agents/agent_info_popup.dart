import 'dart:math' show sin, cos, sqrt, asin;
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/screens/chat/conversation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import 'package:cribs_arena/services/chat_service.dart';
import 'package:cribs_arena/utils/error_handler.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:cribs_arena/services/socket_service.dart';
import 'package:cribs_arena/helpers/chat_helper.dart'; // Added ChatHelper

class AgentInfoPopup extends StatefulWidget {
  final Agent selectedAgent;
  final VoidCallback onDismiss;
  final AnimationController popupAnimationController;
  final AnimationController closeButtonAnimationController;
  final String? propertyTitle; // Added for context-aware messages

  const AgentInfoPopup({
    super.key,
    required this.selectedAgent,
    required this.onDismiss,
    required this.popupAnimationController,
    required this.closeButtonAnimationController,
    this.propertyTitle, // Optional property title
  });

  @override
  State<AgentInfoPopup> createState() => _AgentInfoPopupState();
}

class _AgentInfoPopupState extends State<AgentInfoPopup> {
  late Animation<double> _popupScale;
  late Animation<double> _popupOpacity;
  late Animation<double> _closeScale;
  late final ChatService _chatService;
  bool _isCreatingChat = false;

  static const List<String> _rankLabels = [
    'Reliable',
    'Professional',
    'Superstar',
    'Elite',
    'Trusted Partner',
    'Top Rated',
    'Certified Pro',
    'Expert Realtor',
    'Master Agent',
    'Legendary Agent',
  ];

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _popupScale = Tween<double>(begin: kPopupScaleBegin, end: 1.0).animate(
      CurvedAnimation(
          parent: widget.popupAnimationController, curve: Curves.elasticOut),
    );
    _popupOpacity = Tween<double>(begin: kPopupOpacityBegin, end: 1.0).animate(
      CurvedAnimation(
          parent: widget.popupAnimationController, curve: Curves.easeOut),
    );
    _closeScale = Tween<double>(begin: 1.0, end: kCloseButtonScaleEnd).animate(
      CurvedAnimation(
          parent: widget.closeButtonAnimationController,
          curve: Curves.easeInOut),
    );
  }

  void _onClosePressed() {
    widget.closeButtonAnimationController.forward().then((_) {
      widget.closeButtonAnimationController.reverse();
      widget.onDismiss();
    });
  }

  Future<void> _handleChatCreation() async {
    if (_isCreatingChat) return;
    setState(() => _isCreatingChat = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.user == null) {
        throw Exception('User not logged in.');
      }

      // Construct agent data map
      final agentData = {
        'agent_id': widget.selectedAgent.agentId,
        'first_name': widget.selectedAgent.firstName,
        'last_name': widget.selectedAgent.lastName,
        'profile_image': widget.selectedAgent.profileImage,
      };

      // Use ChatHelper to construct complete chat data
      final chatData = ChatHelper.constructChatData(
        user: userProvider.user!,
        agent: agentData,
        propertyTitle: widget.propertyTitle,
      );

      // Validate chat data
      if (!ChatHelper.validateChatData(chatData)) {
        throw Exception('Invalid chat data');
      }

      debugPrint(
          '💬 Starting chat from agent popup: userId=${chatData['userId']}, agentId=${chatData['agentId']}');

      // Create or find conversation with complete data
      final conversationId = await _chatService.findOrCreateConversation(
        userId: chatData['userId'],
        agentId: chatData['agentId'],
        userName: chatData['userName'],
        userAvatar: chatData['userAvatar'],
        agentName: chatData['agentName'],
        agentAvatar: chatData['agentAvatar'],
        tags: List<String>.from(chatData['tags'] ?? []),
      );

      debugPrint('✅ Conversation created from agent popup: $conversationId');

      // Ensure socket is connected
      if (!SocketService.isConnected()) {
        SocketService.connect(chatData['userId']);
      }

      if (mounted) {
        widget.onDismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversationId,
              otherParticipantId: chatData['agentId'],
              agentName: chatData['agentName'],
              agentImageUrl: chatData['agentAvatar'],
              initialMessage:
                  chatData['initialMessage'], // Pass initial message
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error starting chat from agent popup: $e');
      if (mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingChat = false);
      }
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  ImageProvider _getAgentImageProvider(Agent agent) {
    final String profilePicturePath = agent.profileImage;

    if (profilePicturePath.isEmpty) {
      debugPrint('Agent ${agent.id}: No profile image, using placeholder');
      return const AssetImage('assets/images/default_profile.jpg');
    }

    if (profilePicturePath.startsWith('http')) {
      debugPrint('Agent ${agent.id}: Using full URL: $profilePicturePath');
      return NetworkImage(profilePicturePath);
    }

    // Clean the path
    String agentImagePath = profilePicturePath;

    // Remove leading slash if present
    if (agentImagePath.startsWith('/')) {
      agentImagePath = agentImagePath.substring(1);
    }

    // If it's already a full storage path (e.g., "storage/agent_pictures/1.jpg")
    if (agentImagePath.startsWith('storage/')) {
      final String fullImageUrl = '$kMainBaseUrl$agentImagePath';
      debugPrint('Agent ${agent.id}: Full storage path: $fullImageUrl');
      return NetworkImage(fullImageUrl);
    }

    // If it's a relative path like "agent_pictures/1.jpg" or "profile_pictures/xxx.jpg"
    if (agentImagePath.contains('agent_pictures/') ||
        agentImagePath.contains('profile_pictures/')) {
      final String fullImageUrl = '${kMainBaseUrl}storage/$agentImagePath';
      debugPrint('Agent ${agent.id}: Relative path: $fullImageUrl');
      return NetworkImage(fullImageUrl);
    }

    // If it's just a filename, try agent_pictures first
    // This handles cases where only the filename is stored (e.g., "1.jpg")
    if (!agentImagePath.contains('/')) {
      final String fullImageUrl =
          '${kMainBaseUrl}storage/agent_pictures/$agentImagePath';
      debugPrint('Agent ${agent.id}: Filename only: $fullImageUrl');
      return NetworkImage(fullImageUrl);
    }

    // Default fallback - assume it needs storage prefix
    final String fullImageUrl = '${kMainBaseUrl}storage/$agentImagePath';
    debugPrint('Agent ${agent.id}: Default fallback: $fullImageUrl');
    return NetworkImage(fullImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.selectedAgent;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final String name = a.fullName;

    final int rankIndex = a.totalSales ?? 0;
    final String rankLabel =
        _rankLabels[rankIndex.clamp(0, _rankLabels.length - 1)];

    // Calculate distance between user and agent
    double? distanceKm;
    final userLat = userProvider.user?['latitude'];
    final userLng = userProvider.user?['longitude'];
    final agentLat = a.latitude;
    final agentLng = a.longitude;

    if (userLat != null &&
        userLng != null &&
        agentLat != null &&
        agentLng != null) {
      distanceKm = _calculateDistance(
        double.tryParse(userLat.toString()) ?? 0.0,
        double.tryParse(userLng.toString()) ?? 0.0,
        agentLat,
        agentLng,
      );
    }

    final String distanceText = distanceKm != null && distanceKm > 0
        ? '${distanceKm.toStringAsFixed(2)} km away'
        : 'Distance unknown';

    final double rating = a.averageRating ?? 0.0;
    final String area = a.area ?? kLocationNotAvailableText;

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: kBlackOpacity03,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: AnimatedBuilder(
                animation: widget.popupAnimationController,
                builder: (_, __) {
                  return Transform.scale(
                    scale: _popupScale.value,
                    child: Opacity(
                      opacity: _popupOpacity.value,
                      child: Material(
                        elevation: kElevation12,
                        borderRadius: kRadius20,
                        color: Colors.transparent,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width *
                                  kMaxWidth085,
                              padding: kPaddingAll16,
                              decoration: const BoxDecoration(
                                color: kWhite,
                                borderRadius: kRadius20,
                                boxShadow: [
                                  BoxShadow(
                                    color: kBlackOpacity015,
                                    blurRadius: kBlurRadius30,
                                    offset: kOffset015,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: kRadius35 * 2,
                                        height: kRadius35 * 2,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: ClipOval(
                                          child: Image(
                                            image: _getAgentImageProvider(a),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/default_profile.jpg',
                                                fit: BoxFit.cover,
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2.0,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                          Color>(kPrimaryColor),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: kSizedBoxW12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: kPaddingH8V4,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: kPrimaryColor,
                                                    borderRadius: kRadius12,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.shield,
                                                          color: kWhite,
                                                          size: kIconSize12),
                                                      const SizedBox(
                                                          width: kSizedBoxW4),
                                                      Text(
                                                        rankLabel,
                                                        style: const TextStyle(
                                                          color: kWhite,
                                                          fontSize: kFontSize10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                const Icon(Icons.star,
                                                    color: kAmber,
                                                    size: kIconSize16),
                                                const SizedBox(
                                                    width: kSizedBoxW4),
                                                Text(
                                                  rating.toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: kFontSize14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: kSizedBoxH8),
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: kFontSize18,
                                                fontWeight: FontWeight.bold,
                                                color: kBlack87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: kSizedBoxH4),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    color: kGrey600,
                                                    size: kIconSize14),
                                                const SizedBox(
                                                    width: kSizedBoxW4),
                                                Expanded(
                                                  child: Text(
                                                    area,
                                                    style: const TextStyle(
                                                      fontSize: kFontSize12,
                                                      color: kGrey600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: kSizedBoxH16),
                                  ElevatedButton(
                                    onPressed: _isCreatingChat
                                        ? null
                                        : _handleChatCreation,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor,
                                      foregroundColor: kWhite,
                                      minimumSize: const Size(
                                          double.infinity, kSizedBoxH48),
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: kRadius16),
                                    ),
                                    child: Text(
                                      _isCreatingChat
                                          ? 'Starting...'
                                          : kChatText,
                                      style: const TextStyle(
                                        fontSize: kFontSize14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: kSizedBoxH16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: kSizedBoxW10,
                                        height: kSizedBoxH10,
                                        decoration: const BoxDecoration(
                                          color: kGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: kSizedBoxW8),
                                      Text(
                                        distanceText,
                                        style: const TextStyle(
                                          color: kGrey800,
                                          fontSize: kFontSize12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: kTopNeg15,
                              right: kRightNeg15,
                              child: AnimatedBuilder(
                                animation:
                                    widget.closeButtonAnimationController,
                                builder: (_, __) {
                                  return Transform.scale(
                                    scale: _closeScale.value,
                                    child: GestureDetector(
                                      onTap: _onClosePressed,
                                      child: Container(
                                        width: kSizedBoxW36,
                                        height: kSizedBoxH36,
                                        decoration: const BoxDecoration(
                                          color: kWhite,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: kBlack26,
                                              blurRadius: kBlurRadius6,
                                              offset: kOffset02,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.close,
                                            color: kBlack87, size: kIconSize20),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
