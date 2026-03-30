import 'package:cribs_arena/services/firebase_messaging_service.dart';
import 'package:cribs_arena/main.dart' show navigatorKey;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import 'location_permission_screen.dart';

class PermitNotificationDialog extends StatelessWidget {
  const PermitNotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: kRadius24),
      backgroundColor: kWhite,
      child: Padding(
        padding: kPaddingH24V32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleImageContainer(
              imagePath: 'assets/images/notification_bell.png',
              size: 60,
            ),
            const SizedBox(height: 24),
            const Text(
              'Allow Cribs\'s Arena to send you notifications?',
              textAlign: TextAlign.center,
              style: kDialogTitleStyle,
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                DialogButton(
                  text: kAllowText,
                  onPressed: () async {
                    PermissionStatus status =
                        await Permission.notification.request();
                    debugPrint('Permission request result: $status');

                    if (status.isGranted) {
                      // Send FCM token to server when permission is granted
                      try {
                        await FirebaseMessagingService(navigatorKey)
                            .sendTokenToServer();
                        debugPrint('Token sent successfully.');
                      } catch (e) {
                        debugPrint('Error sending token to server: $e');
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } else if (status.isPermanentlyDenied) {
                      debugPrint('Status is permanently denied.');
                      if (context.mounted) {
                        await showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return CustomAlertDialog(
                              title: const Text('Permission Required'),
                              content: const Text(
                                  'To enable notifications, you need to go to your phone\'s settings for the app.'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Open Settings'),
                                  onPressed: () {
                                    openAppSettings();
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } else {
                      debugPrint('Status is denied (but not permanently).');
                      if (context.mounted) {
                        Navigator.of(context).pop(false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                DialogButton(
                  text: kDontAllowText,
                  onPressed: () {
                    Navigator.of(context).pop(false);
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

class PermitNotificationScreen extends StatefulWidget {
  const PermitNotificationScreen({super.key});

  @override
  State<PermitNotificationScreen> createState() =>
      _PermitNotificationScreenState();
}

class _PermitNotificationScreenState extends State<PermitNotificationScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.notification.status;
    debugPrint('Notification Permission Status: $status');

    if (status.isGranted) {
      // Permission already granted, navigate
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LocationPermissionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Padding(
          padding: kPaddingH24V16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const CircleImageContainer(
                imagePath: 'assets/images/notification_bell.png',
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                'NEVER MISS AN UPDATE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kBlack,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No dull yourself o!\nOn your notification so you no go miss any new property update. The one wey you dey find fit drop anytime!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kBlack54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),
              PrimaryButton(
                text: 'Turn on notification',
                onPressed: () async {
                  final granted = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const PermitNotificationDialog(),
                  );

                  if (granted == true) {
                    _navigateToNextScreen();
                  } else if (granted == false) {
                    // User denied permission, skip to next screen
                    debugPrint('User denied notification permission');
                    _navigateToNextScreen();
                  }
                },
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
