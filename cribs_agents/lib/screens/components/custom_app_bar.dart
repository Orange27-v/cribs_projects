import 'package:cribs_agents/screens/schedule/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/screens/notification/notification_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;

  final VoidCallback? onCalendarPressed;
  final VoidCallback? onNotificationPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.actions,
    this.onCalendarPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kWhite,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
              onPressed: () => Navigator.of(context).pop(),
            )
          : const SizedBox.shrink(),
      leadingWidth: showBackButton ? 56.0 : 0.0,
      title: Padding(
        padding: const EdgeInsets.only(
          left: 20.0,
        ), // Match notification padding
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: kGrey, fontSize: 14),
                ),
            ],
          ),
        ),
      ),
      titleSpacing: 0.0,
      actions: actions ??
          [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderActionButton(
                    svgPath: 'assets/icons/calender.svg',
                    onPressed: onCalendarPressed ??
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyScheduleScreen(),
                            ),
                          );
                        },
                    backgroundColor: kGrey100,
                  ),
                  const SizedBox(width: 8),
                  _HeaderActionButton(
                    svgPath: 'assets/icons/notification.svg',
                    onPressed: onNotificationPressed ??
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                    backgroundColor: kGrey100,
                  ),
                ],
              ),
            ),
          ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 80 : kToolbarHeight);
}

/// Private widget to encapsulate the IconButton with its SVG icon and background.
class _HeaderActionButton extends StatelessWidget {
  final String svgPath;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _HeaderActionButton({
    required this.svgPath,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(svgPath, height: 24, width: 24),
      ),
    );
  }
}
