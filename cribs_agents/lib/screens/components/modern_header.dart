import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/agent_notification_service.dart';
import 'package:cribs_agents/services/agent_inspection_service.dart';

class ModernHeader extends StatefulWidget {
  final String title;
  final VoidCallback? onCalendarPressed;
  final VoidCallback? onNotificationPressed;
  final List<Widget>? actions;
  final String? subtitle;
  final TextStyle? subtitleStyle;

  const ModernHeader({
    super.key,
    required this.title,
    this.onCalendarPressed,
    this.onNotificationPressed,
    this.actions,
    this.subtitle,
    this.subtitleStyle,
  });

  @override
  State<ModernHeader> createState() => _ModernHeaderState();
}

class _ModernHeaderState extends State<ModernHeader> {
  final AgentNotificationService _notificationService =
      AgentNotificationService();
  final AgentInspectionService _inspectionService = AgentInspectionService();

  int _upcomingInspectionsCount = 0;
  int _unreadNotificationsCount = 0;
  bool _isLoading = false;
  StreamSubscription<int>? _inspectionSubscription;
  StreamSubscription<int>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _setupStreams();
  }

  @override
  void dispose() {
    _inspectionSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupStreams() {
    _inspectionSubscription =
        _inspectionService.getUpcomingInspectionsCountStream().listen((count) {
      if (mounted) {
        setState(() {
          _upcomingInspectionsCount = count;
        });
      }
    });

    _notificationSubscription = _notificationService
        .getUnreadNotificationsCountStream()
        .listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    });
  }

  Future<void> _loadCounts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch both counts in parallel
      final results = await Future.wait([
        _inspectionService.getUpcomingCount(),
        _notificationService.getUnreadCount(),
      ]);

      if (mounted) {
        setState(() {
          _upcomingInspectionsCount = results[0];
          _unreadNotificationsCount = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts: $e');
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                if (widget.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.subtitle!.contains('Plan:'))
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                        if (widget.subtitle!.contains('Plan:'))
                          const SizedBox(width: 4),
                        Text(
                          widget.subtitle!,
                          style: widget.subtitleStyle ??
                              GoogleFonts.roboto(
                                fontSize: 13,
                                color: kGrey600,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (widget.actions != null)
            Row(children: widget.actions!)
          else
            Row(
              children: [
                if (widget.onCalendarPressed != null)
                  _HeaderIconButton(
                    svgPath: 'assets/icons/calender.svg',
                    onPressed: widget.onCalendarPressed!,
                    count: _upcomingInspectionsCount,
                  ),
                if (widget.onCalendarPressed != null &&
                    widget.onNotificationPressed != null)
                  const SizedBox(width: 12),
                if (widget.onNotificationPressed != null)
                  _HeaderIconButton(
                    svgPath: 'assets/icons/notification.svg',
                    onPressed: widget.onNotificationPressed!,
                    count: _unreadNotificationsCount,
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
