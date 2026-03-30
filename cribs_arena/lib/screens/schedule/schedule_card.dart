import 'package:cribs_arena/screens/chat/conversation.dart';

import 'package:cribs_arena/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:cribs_arena/utils/error_handler.dart';
import 'package:flash/flash.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/screens/agents/agent_profile_bottom_sheet.dart';
import 'package:cribs_arena/services/update_inspection_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_arena/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cribs_arena/models/property.dart'; // Import the Property model
import 'package:cribs_arena/utils/string_extensions.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/helpers/chat_helper.dart';

class ScheduleCard extends StatefulWidget {
  final dynamic booking;
  final VoidCallback? onStatusChanged;
  final UpdateInspectionService updateInspectionService;

  const ScheduleCard(
      {super.key,
      required this.booking,
      this.onStatusChanged,
      required this.updateInspectionService});

  @override
  State<ScheduleCard> createState() => ScheduleCardState();
}

class ScheduleCardState extends State<ScheduleCard> {
  late dynamic _booking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _cancelBooking(String reason) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.updateInspectionService.cancelInspection(
        inspectionId: _booking['id'],
        reason: reason,
      );
      if (mounted) {
        widget.onStatusChanged?.call();
        SnackbarHelper.showInfo(context, 'Booking status updated to Cancelled.',
            position: FlashPosition.bottom);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeBooking() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.updateInspectionService.completeInspection(
        inspectionId: _booking['id'],
      );
      if (mounted) {
        widget.onStatusChanged?.call();
        SnackbarHelper.showInfo(context, 'Booking status updated to Completed.',
            position: FlashPosition.bottom);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rescheduleBooking(DateTime newDate, TimeOfDay newTime) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.updateInspectionService.rescheduleInspection(
        inspectionId: _booking['id'],
        newDate: newDate,
        newTime: newTime,
      );
      if (mounted) {
        widget.onStatusChanged?.call();
        SnackbarHelper.showInfo(context, 'Reschedule Complete',
            position: FlashPosition.bottom);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startOrNavigateToChat() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;
      final agent = Agent.fromJson(_booking['agent']);

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get user_id and validate
      final rawUserId = currentUser['user_id'];
      if (rawUserId == null) {
        throw Exception('User ID not found. Please log in again.');
      }

      final userId = 'user_$rawUserId'; // Add user_ prefix for MongoDB format
      final agentId = 'agent_${agent.agentId}';

      final chatService = ChatService();
      // Create prefilled message with booking details
      final property = _booking['property'];
      final propertyTitle = property?['title'] ?? 'the property';
      final bookingDate = _booking['booking_date'] != null
          ? DateFormat('MMM d, yyyy')
              .format(DateTime.parse(_booking['booking_date']))
          : '';

      final userAvatarUrl =
          ChatHelper.getFullImageUrl(currentUser['profile_picture_url']);
      final agentAvatarUrl = ChatHelper.getFullImageUrl(agent.profileImage);

      debugPrint('👤 User avatar URL: $userAvatarUrl');
      debugPrint('👨‍💼 Agent avatar URL: $agentAvatarUrl');

      final conversationId = await chatService.findOrCreateConversation(
        userId: userId,
        agentId: agentId,
        userName: currentUser['full_name'] ?? 'You',
        userAvatar: userAvatarUrl,
        agentName: agent.fullName,
        agentAvatar: agentAvatarUrl,
        tags: [
          'Booking Inquiry',
          if (propertyTitle != 'the property') 'Property: $propertyTitle',
          if (bookingDate.isNotEmpty) 'Date: $bookingDate',
        ],
      );

      if (mounted) {
        final prefilledMessage = bookingDate.isNotEmpty
            ? 'Hi! I have a booking for $propertyTitle on $bookingDate. '
            : 'Hi! I have a booking for $propertyTitle. ';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversationId,
              otherParticipantId: agentId,
              agentName: agent.fullName,
              agentImageUrl: agentAvatarUrl,
              initialMessage: prefilledMessage,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: kRadius12,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey(widget.booking['id']),
          tilePadding: const EdgeInsets.all(10),
          title: _buildTitle(),
          children: <Widget>[
            _buildExpandedContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final agentData = _booking['agent'];
    if (agentData == null) {
      // Handle case where agent data is missing
      return Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: kGrey100,
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 380 ? 8 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unknown Agent',
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
      ]);
    }
    final Agent agent = Agent.fromJson(agentData);
    final agentName = agent.fullName;
    final agentImage = (agent.profileImage.isNotEmpty)
        ? NetworkImage(ChatHelper.getFullImageUrl(agent.profileImage))
        : const AssetImage('assets/images/default_profile.jpg')
            as ImageProvider;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AgentProfileBottomSheet(agent: agent),
            );
          },
          child: CircleAvatar(
            radius: 28,
            backgroundImage: agentImage,
            backgroundColor: kGrey100,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 380 ? 8 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agentName,
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

  Widget _buildStatusTags() {
    final status = _booking['status']?.toLowerCase() ?? 'scheduled';

    Color statusColor;
    Color statusBgColor;
    Color statusBorderColor;

    switch (status) {
      case 'completed':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade50;
        statusBorderColor = Colors.green.shade200;
        break;
      case 'cancelled':
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.shade50;
        statusBorderColor = Colors.red.shade200;
        break;
      case 'rescheduled':
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
        statusBorderColor = Colors.orange.shade200;
        break;
      default: // scheduled
        statusColor = Colors.blue.shade700;
        statusBgColor = Colors.blue.shade50;
        statusBorderColor = Colors.blue.shade200;
    }

    return Row(
      children: [
        Expanded(
          child: Container(
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
                  colorFilter:
                      const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "House Inspection",
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize8,
                      fontWeight: FontWeight.w500,
                      color: kPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 380 ? 4 : 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: kRadius16,
              border: Border.all(
                color: statusBorderColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                capitalizeString(status),
                style: GoogleFonts.roboto(
                  fontSize: kFontSize8,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeAndAmount() {
    final inspectionDateTime = DateTime.parse(_booking['inspection_date']);
    final amount = _booking['amount'] ?? 0;
    final formattedDate = DateFormat('E, d MMM').format(inspectionDateTime);
    final formattedTime = DateFormat('h:mm a').format(inspectionDateTime);

    return Row(
      children: [
        SvgPicture.asset(
          "assets/icons/calender.svg",
          height: 16,
          width: 16,
          colorFilter: const ColorFilter.mode(kGrey, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Flexible(
          flex: 3,
          child: Text(
            '$formattedDate, $formattedTime',
            style: GoogleFonts.roboto(fontSize: kFontSize10, color: kBlack54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 380 ? 4 : 12),
        SvgPicture.asset(
          "assets/icons/coin-alt.svg",
          height: 16,
          width: 16,
          colorFilter: const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Flexible(
          flex: 2,
          child: Text(
            '$nairaSymbol $amount',
            style: kNairaSymbolTextStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

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
          _buildFooterActions(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPropertyInfo() {
    final propertyData = _booking['property'];
    if (propertyData == null) {
      return Container(); // Return an empty container or a placeholder
    }
    final property = Property.fromJson(propertyData); // Cast to Property model
    final title =
        property.title.isNotEmpty ? property.title : 'Unknown Property';
    final address =
        property.address?.isNotEmpty == true ? property.address! : 'No address';

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
              style: GoogleFonts.roboto(fontSize: kFontSize12, color: kBlack54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return _ActionButton(
      icon: "assets/icons/chat.svg",
      label: "Chat",
      onTap: _startOrNavigateToChat,
    );
  }

  Widget _buildFooterActions() {
    final status = _booking['status']?.toLowerCase() ?? 'scheduled';

    if (_isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Text(
          'Cancelled: ${_booking['reason_cancellation'] ?? 'No reason provided.'}',
          style: GoogleFonts.roboto(color: Colors.red, fontSize: kFontSize12),
        ),
      );
    }

    if (status == 'completed') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _FooterAction(
            text: "Completed",
            color: Colors.green,
            iconWidget: SvgPicture.asset(
              'assets/icons/success.svg',
              height: 16,
              width: 16,
            ),
            onTap: () {}, // No action, just for display
          ),
        ],
      );
    }

    // Default state (e.g., 'scheduled' or 'rescheduled')
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _FooterAction(
            text: "Cancel",
            color: Colors.red,
            icon: Icons.close,
            onTap: () => _showCancelModal(context),
          ),
        ),
        Expanded(
          child: _FooterAction(
            text: "Complete",
            color: Colors.lightGreen,
            icon: Icons.check,
            onTap: () => _showCompleteModal(context),
          ),
        ),
        Expanded(
          child: _FooterAction(
            text: "Reschedule",
            color: kPrimaryColor,
            icon: Icons.schedule,
            onTap: () => _showRescheduleModal(context),
          ),
        ),
      ],
    );
  }

  void _showCancelModal(BuildContext context) {
    final reasonController = TextEditingController();
    bool isCancelling = false;
    CustomBottomSheet.show(
      context: context,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cancel Appointment',
                    style: kTitleStyle.copyWith(fontSize: kFontSize18)),
                const SizedBox(height: kSizedBoxH16),
                LabeledTextField(
                  controller: reasonController,
                  label: 'Reason for cancellation',
                  hintText: 'Enter reason (optional)',
                  maxLines: 3,
                ),
                const SizedBox(height: kSizedBoxH24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedActionButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                        borderColor: kPrimaryColor,
                        textColor: kPrimaryColor,
                        borderRadius: 32.0,
                      ),
                    ),
                    const SizedBox(width: kSizedBoxW12),
                    Expanded(
                      child: isCancelling
                          ? const Center(child: CustomLoadingIndicator())
                          : PrimaryButton(
                              text: 'Confirm Cancellation',
                              onPressed: () async {
                                setModalState(() {
                                  isCancelling = true;
                                });
                                await _cancelBooking(reasonController.text);
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              backgroundColor: kRed,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRescheduleModal(BuildContext context) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isRescheduling = false;

    CustomBottomSheet.show(
      context: context,
      initialChildSize: 0.5,
      maxChildSize: 0.7,
      minChildSize: 0.4,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reschedule Appointment',
                  style: kTitleStyle.copyWith(fontSize: kFontSize18)),
              const SizedBox(height: kSizedBoxH20),
              ListTile(
                title: Text(selectedDate == null
                    ? 'Select Date'
                    : DateFormat('E, d MMM yyyy').format(selectedDate!)),
                trailing: SvgPicture.asset(
                  kCalendarIconPath,
                  height: kIconSize24,
                  width: kIconSize24,
                  colorFilter:
                      const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setModalState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: Text(selectedTime == null
                    ? 'Select Time'
                    : selectedTime!.format(context)),
                trailing: const Icon(Icons.access_time, color: kPrimaryColor),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setModalState(() {
                      selectedTime = pickedTime;
                    });
                  }
                },
              ),
              const SizedBox(height: kSizedBoxH24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedActionButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      borderColor: kPrimaryColor,
                      textColor: kPrimaryColor,
                      borderRadius: 32.0,
                    ),
                  ),
                  const SizedBox(width: kSizedBoxW12),
                  Expanded(
                    child: isRescheduling
                        ? const Center(child: CustomLoadingIndicator())
                        : PrimaryButton(
                            text: 'Confirm Reschedule',
                            onPressed:
                                (selectedDate != null && selectedTime != null)
                                    ? () async {
                                        setModalState(() {
                                          isRescheduling = true;
                                        });
                                        await _rescheduleBooking(
                                          selectedDate!,
                                          selectedTime!,
                                        );
                                        if (mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    : null,
                            backgroundColor: kPrimaryColor,
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCompleteModal(BuildContext context) {
    bool isCompleting = false;

    CustomBottomSheet.show(
      context: context,
      initialChildSize: 0.3,
      maxChildSize: 0.4,
      minChildSize: 0.25,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mark as Complete',
                  style: kTitleStyle.copyWith(fontSize: kFontSize18)),
              const SizedBox(height: kSizedBoxH16),
              Text(
                  'Are you sure you want to mark this appointment as complete?',
                  style: kSubtitleStyle.copyWith(fontSize: kFontSize14)),
              const SizedBox(height: kSizedBoxH24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedActionButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      borderColor: kPrimaryColor,
                      textColor: kPrimaryColor,
                      borderRadius: 32.0,
                    ),
                  ),
                  const SizedBox(width: kSizedBoxW12),
                  Expanded(
                    child: isCompleting
                        ? const Center(child: CustomLoadingIndicator())
                        : PrimaryButton(
                            text: 'Confirm',
                            onPressed: () async {
                              setModalState(() {
                                isCompleting = true;
                              });
                              await _completeBooking();
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            backgroundColor: kGreen,
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
        height: kSizedBoxH48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              colorFilter:
                  const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: kFontSize14,
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

class _FooterAction extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;

  const _FooterAction({
    required this.text,
    required this.color,
    this.icon,
    this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: kRadius8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ?? Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.roboto(
                color: color,
                fontSize: kFontSize10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
