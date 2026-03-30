import 'dart:async';
import 'package:flutter/material.dart';
import 'verification_banner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants.dart';
import '../../services/agent_notification_service.dart';
import '../../services/agent_inspection_service.dart';
import '../../provider/agent_provider.dart';
import 'package:provider/provider.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
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
                    _HeaderActionButton(
                      svgPath: 'assets/icons/calender.svg',
                      onPressed: widget.onCalendarPressed,
                      backgroundColor: kGrey100,
                      count: _upcomingInspectionsCount,
                    ),
                    const SizedBox(width: 8),
                    _HeaderActionButton(
                      svgPath: 'assets/icons/notification.svg',
                      onPressed: widget.onNotificationPressed,
                      backgroundColor: kGrey100,
                      count: _unreadNotificationsCount,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const VerificationBanner(),
      ],
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final String? area;
  const _LocationInfo({this.area});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        final agentArea = area ?? agentProvider.agent?.area;
        final locationText = (agentArea != null && agentArea.isNotEmpty)
            ? '$agentArea, Nigeria'
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
                  Text(
                    'Cribs Agents',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kBlack,
                    ),
                  ),
                  Text(
                    locationText,
                    style: GoogleFonts.roboto(
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
                    style: GoogleFonts.roboto(
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
