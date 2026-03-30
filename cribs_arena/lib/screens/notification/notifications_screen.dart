import 'dart:async';
import 'package:cribs_arena/exceptions/network_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/widgets.dart'; // For PrimaryButton
import '../../constants.dart'; // For kGrey100 etc.
import '../../utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import '../../services/auth_service.dart'; // Import AuthService

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  Stream<List<NotificationModel>>? _notificationsStream;
  String? _errorMessage;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _markAllNotificationsAsRead(); // Call this when screen initializes
  }

  Future<void> _initializeStream() async {
    final token = await _authService.getToken();
    if (mounted) {
      if (token == null) {
        setState(() {
          _errorMessage = "You are not logged in.";
        });
      } else {
        _notificationService.setAuthToken(token);
        setState(() {
          _token = token;
          _notificationsStream = _notificationService.getNotificationsStream();
        });
      }
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    final result = await _notificationService.markAllAsRead();
    if (mounted && result.isError) {
      SnackbarHelper.showError(
          context, result.error?.message ?? 'Failed to mark all as read.',
          position: FlashPosition.bottom);
    }
  }

  Future<void> _handleRefresh() async {
    if (_token != null) {
      await _notificationService.fetchLatestNotifications();
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (_token == null) return;

    final result =
        await _notificationService.markNotificationAsRead(notificationId);
    if (mounted && result.isError) {
      SnackbarHelper.showError(
          context, result.error?.message ?? 'Failed to mark as read.',
          position: FlashPosition.bottom);
    }
    // No need to show success or manually refresh, as the stream will update automatically.
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
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('Notifications'),
      ),
      body: CustomRefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<List<NotificationModel>>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            if (_errorMessage != null) {
              return Center(
                child: CardContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Retry',
                        onPressed: _initializeStream,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CustomLoadingIndicator());
            } else if (snapshot.hasError) {
              String errorMessage;
              if (snapshot.error is NetworkException) {
                errorMessage = (snapshot.error as NetworkException).message;
              } else {
                errorMessage = snapshot.error.toString();
              }
              return Center(
                child: CardContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Retry',
                        onPressed: _initializeStream,
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
                              imagePath: 'assets/images/magnifier.png',
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

              // Sort the groups by date (Today, Yesterday, then chronological for older dates)
              final sortedGroupEntries = groupedNotifications.entries.toList();
              sortedGroupEntries.sort((a, b) {
                // Custom sort order: Today, Yesterday, then newest to oldest for other dates
                if (a.key == 'Today') return -1;
                if (b.key == 'Today') return 1;
                if (a.key == 'Yesterday') return -1;
                if (b.key == 'Yesterday') return 1;

                // For other dates, sort by the actual date (newest first)
                final dateA = a.value.first.createdAt;
                final dateB = b.value.first.createdAt;
                return dateB.compareTo(dateA);
              });

              return CardContainer(
                padding: const EdgeInsets.all(
                    0), // CardContainer already has padding, ListView will handle item spacing
                child: ListView(
                  padding: const EdgeInsets.all(
                      16.0), // Keep padding for the list items
                  children: [
                    for (var entry in sortedGroupEntries) ...[
                      _buildSectionHeader(entry.key),
                      ...entry.value.map((n) => _buildNotificationItem(n,
                              isNew: !n.isRead, onTap: () {
                            if (!n.isRead) {
                              _markAsRead(n.id);
                            }
                          })),
                      const SizedBox(
                          height: 16), // Add some space between groups
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
          fontWeight: FontWeight.w500,
          fontSize: kFontSize12,
        ),
      ),
    );
  }

  String _getIconPathForType(String type) {
    switch (type) {
      case 'chat':
        return 'assets/icons/chat.svg';
      case 'booking_update':
      case 'inspection_update':
        return 'assets/icons/calender.svg';
      case 'new_listing':
        return 'assets/icons/house.svg';
      case 'payment_confirmation':
      case 'payment_received':
        return 'assets/icons/file-narrow.svg'; // Example, adjust as needed
      default:
        return 'assets/icons/file-narrow.svg'; // A generic icon
    }
  }

  Widget _buildNotificationItem(NotificationModel notification,
      {required bool isNew, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                      fontWeight: FontWeight.bold,
                      fontSize: kFontSize12,
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
