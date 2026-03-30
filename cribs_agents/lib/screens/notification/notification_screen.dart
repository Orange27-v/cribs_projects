import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/agent_notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/widgets.dart'; // For EmptyStateWidget etc.
import '../../constants.dart'; // For kGrey100 etc.

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AgentNotificationService _notificationService =
      AgentNotificationService();
  Stream<List<NotificationModel>>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _notificationService.getNotificationsStream();
    _markAllNotificationsAsRead(); // Call this when screen initializes
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _markAllNotificationsAsRead() async {
    await _notificationService.markAllAsRead();
  }

  Future<void> _handleRefresh() async {
    await _notificationService.fetchNotifications();
  }

  Future<void> _markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${notificationDate.month}/${notificationDate.day}/${notificationDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomRefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<List<NotificationModel>>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CustomLoadingIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        onPressed: _handleRefresh,
                        text: 'Retry',
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleImageContainer(
                              imagePath: 'assets/images/avatar_person.png',
                              size: 100,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: kFontSize20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'You\'ll see updates about bookings,\nmessages, and property alerts here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: kFontSize16,
                                color: kGrey,
                              ),
                            ),
                            const SizedBox(height: 30),
                            PrimaryButton(
                              text: 'Go to Home',
                              icon: const Icon(Icons.home, color: kWhite),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              final notifications = snapshot.data!;
              // Group notifications by date
              final Map<String, List<NotificationModel>> groupedNotifications =
                  {};
              for (var notification in notifications) {
                final dateGroup = _getDateGroup(notification.createdAt);
                if (!groupedNotifications.containsKey(dateGroup)) {
                  groupedNotifications[dateGroup] = [];
                }
                groupedNotifications[dateGroup]!.add(notification);
              }

              // Sort the groups by date
              final sortedGroupEntries = groupedNotifications.entries.toList();
              sortedGroupEntries.sort((a, b) {
                if (a.key == 'Today') return -1;
                if (b.key == 'Today') return 1;
                if (a.key == 'Yesterday') return -1;
                if (b.key == 'Yesterday') return 1;
                final dateA = a.value.first.createdAt;
                final dateB = b.value.first.createdAt;
                return dateB.compareTo(dateA);
              });

              return Padding(
                padding: const EdgeInsets.all(0.0),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    for (var entry in sortedGroupEntries) ...[
                      _buildSectionHeader(entry.key),
                      ...entry.value.map((n) => _buildNotificationItem(n,
                              isNew: !n.isRead, onTap: () {
                            if (!n.isRead) {
                              _markAsRead(n.id);
                            }
                          })),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: kGrey,
          fontSize: kFontSize10,
        ),
      ),
    );
  }

  String _getIconPathForType(String type) {
    if (type.contains('chat') || type.contains('message')) {
      return 'assets/icons/chat.svg';
    } else if (type.contains('booking') || type.contains('inspection')) {
      return 'assets/icons/calender.svg';
    } else if (type.contains('payment')) {
      return 'assets/icons/coin-alt.svg';
    } else if (type.contains('property')) {
      return 'assets/icons/house.svg';
    } else {
      return 'assets/icons/notification.svg';
    }
  }

  Widget _buildNotificationItem(NotificationModel notification,
      {required bool isNew, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isNew ? kPrimaryColor.withValues(alpha: 0.05) : kWhite,
          borderRadius: kRadius12,
          border: Border.all(
            color: isNew
                ? kPrimaryColor.withValues(alpha: 0.2)
                : kGrey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              _getIconPathForType(notification.type),
              colorFilter:
                  const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
              height: 28,
              width: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: kFontSize10,
                      color: kBlack87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: kGrey,
                      fontSize: kFontSize10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Text(
                timeago.format(notification.createdAt),
                style: const TextStyle(color: kGrey, fontSize: kFontSize8),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
