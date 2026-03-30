import 'package:cribs_agents/screens/chat/conversation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants.dart';
import '../../services/chat_service.dart';
import '../../services/agent_profile_service.dart';

class AgentInfoPopup extends StatefulWidget {
  final Map<String, dynamic> selectedAgent;
  final VoidCallback onDismiss;
  final AnimationController popupAnimationController;
  final AnimationController closeButtonAnimationController;

  const AgentInfoPopup({
    super.key,
    required this.selectedAgent,
    required this.onDismiss,
    required this.popupAnimationController,
    required this.closeButtonAnimationController,
  });

  @override
  State<AgentInfoPopup> createState() => _AgentInfoPopupState();
}

class _AgentInfoPopupState extends State<AgentInfoPopup>
    with TickerProviderStateMixin {
  late Animation<double> _popupScaleAnimation;
  late Animation<double> _popupOpacityAnimation;
  late Animation<double> _closeButtonScaleAnimation;
  bool _isDismissing = false;
  bool _isNavigating = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final ChatService _chatService = ChatService();
  final AgentProfileService _agentProfileService = AgentProfileService();
  Map<String, dynamic>? _agentProfile;

  @override
  void initState() {
    super.initState();

    _popupScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.popupAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _popupOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.popupAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _closeButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: widget.closeButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize glow animation for online indicator
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _glowController.repeat(reverse: true);

    _fetchAgentProfile();
  }

  Future<void> _fetchAgentProfile() async {
    final result = await _agentProfileService.getAgentProfile();
    if (mounted && result['success']) {
      setState(() {
        _agentProfile = result['data'];
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onCloseButtonPressed() {
    if (_isDismissing || _isNavigating) return;

    setState(() {
      _isDismissing = true;
    });

    widget.onDismiss();
  }

  void _handleChatButtonPressed() async {
    if (_isDismissing || _isNavigating) return;

    if (_agentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent profile not loaded yet')),
      );
      return;
    }

    final user = widget.selectedAgent;
    if (user['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information missing')),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      // Access the data structure correctly
      final data = _agentProfile!['data'];
      if (data == null) {
        throw Exception('Agent profile data is null');
      }

      final agentData = data['agent'];
      final agentInfo = data['agent_information'];

      if (agentData == null || agentInfo == null) {
        throw Exception('Agent or agent information is missing');
      }

      if (kDebugMode) {
        debugPrint('💬 Starting chat from user info popup');
        debugPrint('   User ID: user_${user['id']}');
        debugPrint('   Agent ID: agent_${agentData['agent_id']}');
      }

      final conversationId = await _chatService.findOrCreateConversation(
        userId: 'user_${user['id']}', // ✅ Add 'user_' prefix
        agentId: 'agent_${agentData['agent_id']}', // ✅ Add 'agent_' prefix
        userName: user['name'] as String? ?? 'User',
        userAvatar: user['image'] as String? ?? '',
        agentName: '${agentData['first_name']} ${agentData['last_name']}',
        agentAvatar: agentInfo['profile_picture_url'] ?? '',
      );

      if (kDebugMode) {
        debugPrint('✅ Conversation created/found: $conversationId');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversationId,
              otherParticipantId: 'user_${user['id']}', // ✅ Add 'user_' prefix
              participantName: user['name'] as String? ?? 'User',
              participantImageUrl: user['image'] as String? ?? '',
            ),
          ),
        ).then((_) {
          // After navigation completes, dismiss the popup
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to start chat: $e');
      }
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: (_isDismissing || _isNavigating) ? null : widget.onDismiss,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: screenSize.width,
            height: screenSize.height,
            color: kBlackOpacity03,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap propagation
                child: AnimatedBuilder(
                  animation: widget.popupAnimationController,
                  builder: (context, child) {
                    // Ensure we have minimum scale to prevent zero size
                    final scale = _popupScaleAnimation.value.clamp(0.1, 1.0);
                    final opacity = _popupOpacityAnimation.value.clamp(
                      0.0,
                      1.0,
                    );

                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: screenSize.width * 0.9,
                          constraints: BoxConstraints(
                            minWidth: 200,
                            maxWidth: 380,
                            maxHeight: screenSize.height * 0.7,
                          ),
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(16),
                            color: kWhite,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: kWhite,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Blue-bordered avatar
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF0066CC),
                                                width: 4,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 32,
                                              backgroundImage: (widget
                                                                  .selectedAgent[
                                                              'image'] !=
                                                          null &&
                                                      (widget.selectedAgent[
                                                                  'image']
                                                              as String)
                                                          .isNotEmpty)
                                                  ? NetworkImage(
                                                      widget.selectedAgent[
                                                          'image'] as String)
                                                  : const AssetImage(
                                                          'assets/images/default_profile.jpg')
                                                      as ImageProvider,
                                              backgroundColor:
                                                  Colors.grey[200]!,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  widget.selectedAgent['name']
                                                      as String,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      color: kGrey600,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        widget.selectedAgent[
                                                                    'location']
                                                                as String? ??
                                                            'Location not available',
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize: 13,
                                                          color: const Color(
                                                              0xFF666666),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed:
                                              (_isDismissing || _isNavigating)
                                                  ? null
                                                  : _handleChatButtonPressed,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF0066CC),
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                const Color(0xFF0066CC)
                                                    .withValues(alpha: 0.6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isNavigating
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(kWhite),
                                                  ),
                                                )
                                              : Text(
                                                  'Chat',
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Distance indicator with styled badge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Animated glowing indicator
                                          AnimatedBuilder(
                                            animation: _glowController,
                                            builder: (context, child) {
                                              final isOnline =
                                                  widget.selectedAgent[
                                                          'isOnline'] ==
                                                      true;
                                              return Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: isOnline
                                                      ? const Color(0xFF4CAF50)
                                                      : Colors.grey,
                                                  shape: BoxShape.circle,
                                                  boxShadow: isOnline
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFF4CAF50)
                                                                .withValues(
                                                                    alpha: 0.4 *
                                                                        _glowAnimation
                                                                            .value),
                                                            blurRadius: 8 *
                                                                _glowAnimation
                                                                    .value,
                                                            spreadRadius: 3 *
                                                                _glowAnimation
                                                                    .value,
                                                          ),
                                                        ]
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Close to you',
                                            style: GoogleFonts.roboto(
                                              color: const Color(0xFF666666),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${widget.selectedAgent['distance'] ?? '< 1'}km',
                                              style: GoogleFonts.roboto(
                                                color: const Color(0xFF0066CC),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Close button
                                if (!_isNavigating)
                                  Positioned(
                                    top: -12,
                                    right: -12,
                                    child: AnimatedBuilder(
                                      animation:
                                          widget.closeButtonAnimationController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale:
                                              _closeButtonScaleAnimation.value,
                                          child: GestureDetector(
                                            onTap: _onCloseButtonPressed,
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: const BoxDecoration(
                                                color: kWhite,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: kBlack26,
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: kBlack87,
                                                size: 18,
                                              ),
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
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
