// lib/screens/user/user_widgets/app_header_content.dart
import 'package:cribs_arena/services/inspection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants.dart';
import 'package:cribs_arena/services/notification_service.dart';
import 'package:cribs_arena/services/user_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';

class AppHeaderContent extends StatefulWidget {
  final double horizontalPadding;
  final double verticalPadding;
  final VoidCallback onNotificationPressed;
  final VoidCallback onCalendarPressed;
  final String? area;

  const AppHeaderContent({
    super.key,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.onNotificationPressed,
    required this.onCalendarPressed,
    this.area,
  });

  @override
  State<AppHeaderContent> createState() => _AppHeaderContentState();
}

class _AppHeaderContentState extends State<AppHeaderContent> {
  final InspectionService _inspectionService = InspectionService();

  final NotificationService _notificationService = NotificationService();

  final UserAuthService _userAuthService = UserAuthService();

  String? _authToken;

  Stream<int>? _unreadCountStream;

  @override
  void initState() {
    super.initState();

    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    _authToken = await _userAuthService.getToken();
    debugPrint('Auth Token loaded: $_authToken');

    // Always get the stream (it will emit 0 if no token)
    setState(() {
      _unreadCountStream =
          _notificationService.getUnreadNotificationsCountStream();
    });

    // Set token and trigger initial fetch after stream is created
    if (_authToken != null) {
      _notificationService.setAuthToken(_authToken!);
      // Manually trigger fetch to update the count
      _notificationService.fetchLatestUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: kWhite,
      elevation: 2.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
          top: widget.verticalPadding,
          bottom: widget.verticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LocationInfo(area: widget.area),

            /// Real-time inspection count and notification count

            Row(
              children: [
                StreamBuilder<int>(
                  stream:
                      _inspectionService.getUpcomingInspectionsCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;

                    return _HeaderActionButton(
                      svgPath: 'assets/icons/calender.svg',
                      onPressed: widget.onCalendarPressed,
                      backgroundColor: kGrey100,
                      count: count,
                    );
                  },
                ),
                const SizedBox(width: 8),
                StreamBuilder<int>(
                  stream: _unreadCountStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint(
                          'Error in notification count stream: ${snapshot.error}');
                    }
                    // Always show count, default to 0 if no data or error
                    final notificationCount =
                        snapshot.hasData ? snapshot.data! : 0;
                    return _HeaderActionButton(
                      svgPath: 'assets/icons/notification.svg',
                      onPressed: widget.onNotificationPressed,
                      backgroundColor: kGrey100,
                      count: notificationCount,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final String? area;
  const _LocationInfo({this.area});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final displayArea = area ?? userProvider.area;
        final locationText = (displayArea != null && displayArea.isNotEmpty)
            ? '$displayArea, Nigeria'
            : 'Nigeria';

        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              Image.asset(
                'assets/images/location_icon.png',
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cribs Arena',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kBlack,
                    ),
                  ),
                  Text(
                    locationText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: kBlack54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String svgPath;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final int? count;

  const _HeaderActionButton({
    required this.svgPath,
    required this.onPressed,
    this.backgroundColor,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              svgPath,
              height: 25,
              width: 25,
            ),
          ),
          if (count != null && count! > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: kWhite, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
