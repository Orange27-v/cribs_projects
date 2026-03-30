import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/services/inspection_service.dart';
import 'package:cribs_arena/services/notification_service.dart';
import 'package:cribs_arena/services/user_auth_service.dart';

class ModernHeader extends StatefulWidget {
  final String title;
  final VoidCallback onCalendarPressed;
  final VoidCallback onNotificationPressed;

  const ModernHeader({
    super.key,
    required this.title,
    required this.onCalendarPressed,
    required this.onNotificationPressed,
  });

  @override
  State<ModernHeader> createState() => _ModernHeaderState();
}

class _ModernHeaderState extends State<ModernHeader> {
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

    // Always get the stream (it will emit 0 if no token)
    if (mounted) {
      setState(() {
        _unreadCountStream =
            _notificationService.getUnreadNotificationsCountStream();
      });
    }

    // Set token and trigger initial fetch after stream is created
    if (_authToken != null) {
      _notificationService.setAuthToken(_authToken!);
      // Manually trigger fetch to update the count
      _notificationService.fetchLatestUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: kWhite,
        border: Border(
          bottom: BorderSide(
            color: kGrey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.roboto(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          Row(
            children: [
              StreamBuilder<int>(
                stream: _inspectionService.getUpcomingInspectionsCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _HeaderIconButton(
                    svgPath: 'assets/icons/calender.svg',
                    onPressed: widget.onCalendarPressed,
                    count: count,
                  );
                },
              ),
              const SizedBox(width: 12),
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
                  return _HeaderIconButton(
                    svgPath: 'assets/icons/notification.svg',
                    onPressed: widget.onNotificationPressed,
                    count: notificationCount,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String svgPath;
  final VoidCallback onPressed;
  final int? count;

  const _HeaderIconButton({
    required this.svgPath,
    required this.onPressed,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kGrey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              svgPath,
              height: 22,
              width: 22,
              colorFilter:
                  const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
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
