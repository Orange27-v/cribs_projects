import 'package:cribs_agents/screens/schedule/edit_schedule_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/services/chat_service.dart';
import 'package:cribs_agents/screens/chat/conversation.dart';
import 'package:provider/provider.dart';
import 'package:cribs_agents/provider/agent_provider.dart';

class ScheduleCard extends StatefulWidget {
  final dynamic inspection;
  const ScheduleCard({super.key, required this.inspection});

  @override
  State<ScheduleCard> createState() => ScheduleCardState();
}

class ScheduleCardState extends State<ScheduleCard> {
  Future<void> _startChat() async {
    final user = widget.inspection['user'];
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User information not available')),
        );
      }
      return;
    }

    try {
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final agentData = agentProvider.agent;

      if (agentData == null) {
        throw Exception('Agent not logged in');
      }

      debugPrint('💬 Starting chat from schedule screen');
      debugPrint('   User ID: user_${user['user_id']}');
      debugPrint('   Agent ID: agent_${agentData.agentId}');

      final chatService = ChatService();
      final conversationId = await chatService.findOrCreateConversation(
        userId: 'user_${user['user_id']}', // ✅ With 'user_' prefix
        agentId: 'agent_${agentData.agentId}', // ✅ With 'agent_' prefix
        userName:
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
        userAvatar: user['profile_picture_url'] ?? '',
        agentName: '${agentData.firstName} ${agentData.lastName}',
        agentAvatar: agentData.profilePictureUrl ?? '',
      );

      debugPrint('✅ Conversation created/found: $conversationId');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversationId,
              otherParticipantId:
                  'user_${user['user_id']}', // ✅ With 'user_' prefix
              participantName:
                  '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                      .trim(),
              participantImageUrl: user['profile_picture_url'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to start chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(10),
          title: _buildTitle(),
          children: <Widget>[_buildExpandedContent()],
        ),
      ),
    );
  }

  // Builds the main title content of the expansion tile.
  Widget _buildTitle() {
    final user = widget.inspection['user'];
    final userName = user != null
        ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()
        : 'Unknown User';
    final profilePictureUrl = user?['profile_picture_url'] as String?;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: kGrey100,
          backgroundImage:
              profilePictureUrl != null && profilePictureUrl.isNotEmpty
                  ? NetworkImage(profilePictureUrl)
                  : const AssetImage('assets/images/default_profile.jpg')
                      as ImageProvider,
          onBackgroundImageError: (_, __) {
            // Silently handle image load errors
            debugPrint('Failed to load profile image: $profilePictureUrl');
          },
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 380 ? 8 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.roboto(
                  fontSize: kFontSize16,
                  fontWeight: FontWeight.w500,
                  color: kBlack,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildStatusTags(),
              const SizedBox(height: 8),
              _buildDateTimeAndAmount(),
            ],
          ),
        ),
      ],
    );
  }

  // Builds the status tags for the appointment.
  Widget _buildStatusTags() {
    final status = widget.inspection['status'] ?? 'scheduled';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: kRadius16,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                "assets/icons/eye.svg",
                height: 12,
                width: 12,
                colorFilter: const ColorFilter.mode(
                  kPrimaryColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "House Inspection",
                style: GoogleFonts.roboto(
                  fontSize: kFontSize8,
                  fontWeight: FontWeight.w500,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 380 ? 4 : 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: kRadius16,
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: Text(
            status,
            style: GoogleFonts.roboto(
              fontSize: kFontSize8,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Builds the row containing date, time, and amount.
  Widget _buildDateTimeAndAmount() {
    final date = DateTime.parse(widget.inspection['inspection_date']);
    final time = widget.inspection['inspection_time'] ?? '';
    final amount = widget.inspection['amount'] ?? 0;
    final formattedDate = DateFormat('E, d MMM').format(date);

    return Row(
      children: [
        SvgPicture.asset(
          "assets/icons/calender.svg",
          height: 16,
          width: 16,
          colorFilter: const ColorFilter.mode(kGrey, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 4,
          child: Text(
            '$formattedDate, $time',
            style: GoogleFonts.roboto(fontSize: kFontSize10, color: kBlack54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 380 ? 4 : 8),
        SvgPicture.asset(
          "assets/icons/coin-alt.svg",
          height: 16,
          width: 16,
          colorFilter: const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 2,
          child: Text(
            '₦$amount Paid',
            style: GoogleFonts.roboto(
              fontSize: kFontSize10,
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Builds the content shown when the tile is expanded.
  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildPropertyInfo(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildStatusInfo(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Builds the status information display
  Widget _buildStatusInfo() {
    final status = widget.inspection['status'] ?? 'scheduled';
    final reasonCancellation = widget.inspection['reason_cancellation'];
    final rescheduleDate = widget.inspection['reschedule_date'];
    final rescheduleTime = widget.inspection['reschedule_time'];

    // Show status-specific information
    if (status == 'cancelled' && reasonCancellation != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: kRadius12,
          border: Border.all(color: Colors.red.shade200, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancelled',
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reason: $reasonCancellation',
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize12,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'rescheduled' && rescheduleDate != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: kRadius12,
          border: Border.all(color: Colors.orange.shade200, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rescheduled',
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New date: $rescheduleDate${rescheduleTime != null ? ' at $rescheduleTime' : ''}',
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'completed') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: kRadius12,
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/success.svg',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Inspection Completed',
              style: GoogleFonts.roboto(
                fontSize: kFontSize14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // For scheduled/confirmed status, return empty container
    return const SizedBox.shrink();
  }

  // Builds the property information section.
  Widget _buildPropertyInfo() {
    final property = widget.inspection['property'];
    final title = property?['title'] ?? 'Unknown Property';
    final address = property?['address'] ?? 'No address';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kGrey100,
        borderRadius: kRadius12,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                "assets/icons/house.svg",
                height: 16,
                width: 16,
                colorFilter: const ColorFilter.mode(kBlack, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  fontSize: kFontSize14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Text(
              address,
              style: GoogleFonts.roboto(
                fontSize: kFontSize12,
                color: kBlack54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the main action buttons (Chat, Edit).
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: "assets/icons/chat.svg",
            label: "Chat",
            onTap: _startChat,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: "assets/icons/profile_user.svg",
            label: "Edit",
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const EditScheduleModal(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: kRadius12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: kLightBlue,
          borderRadius: kRadius12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              height: 18,
              width: 18,
              colorFilter: const ColorFilter.mode(
                kPrimaryColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: kFontSize10,
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
