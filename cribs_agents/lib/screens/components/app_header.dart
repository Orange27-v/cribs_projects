// lib/screens/components/app_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/screens/notification/notification_screen.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int notificationCount;

  final VoidCallback? onNotificationPressed;
  final VoidCallback? onCalendarPressed;
  final VoidCallback? onMapSearchPressed;

  final double horizontalPadding;
  final double verticalPadding;
  final Widget? rightWidget; // New parameter

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.notificationCount = 0,
    this.onNotificationPressed,
    this.onCalendarPressed,
    this.onMapSearchPressed,
    this.horizontalPadding = 20.0,
    this.verticalPadding = 12.0,
    this.rightWidget, // New parameter
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: kWhite,
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 80, // give header breathing room
      flexibleSpace: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LocationInfo(
                title: title,
                subtitle: subtitle,
                onMapSearchPressed: onMapSearchPressed,
              ),
              if (rightWidget != null) // Conditionally show rightWidget
                rightWidget!
              else // Keep existing buttons if rightWidget is null
                Row(
                  children: [
                    // Notification button with optional badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _HeaderActionButton(
                          svgPath: 'assets/icons/notification.svg',
                          onPressed:
                              onNotificationPressed ??
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationScreen(),
                                  ),
                                );
                              },
                          backgroundColor: kGrey100,
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            right: 0,
                            top: -4,
                            child: Container(
                              padding: kPaddingH6V2,
                              decoration: const BoxDecoration(
                                color: kRed,
                                borderRadius: kRadius10,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: kMinWidth18,
                                minHeight: kMinHeight18,
                              ),
                              child: Text(
                                notificationCount > 99
                                    ? '99+'
                                    : '$notificationCount',
                                style: const TextStyle(
                                  color: kWhite,
                                  fontSize: kFontSize10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: kSizedBoxW8),
                    _HeaderActionButton(
                      svgPath: 'assets/icons/calender.svg',
                      onPressed:
                          onCalendarPressed ??
                          () => debugPrint('Calendar tapped'),
                      backgroundColor: kGrey100,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMapSearchPressed;

  const _LocationInfo({
    required this.title,
    this.subtitle,
    this.onMapSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Row(
      children: [
        InkWell(
          onTap: canPop
              ? () => Navigator.pop(context)
              : onMapSearchPressed ?? () {},
          borderRadius: kRadius12,
          child: Container(
            height: kSizedBoxH56,
            width: kSizedBoxW56,
            alignment: AlignmentDirectional.centerStart,
            child: canPop
                ? const Icon(Icons.arrow_back, color: kBlack, size: kFontSize28)
                : Image.asset(
                    'assets/images/location_icon.png',
                    height: kSizedBoxH40,
                    width: kSizedBoxW40,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
        const SizedBox(width: kSizedBoxW2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: kFontSize22,
                fontWeight: FontWeight.w700,
                color: kBlack,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: kFontSize12,
                  fontWeight: FontWeight.w400,
                  color: kBlack54,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

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
        child: SvgPicture.asset(
          svgPath,
          height: 35,
          width: 35,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
