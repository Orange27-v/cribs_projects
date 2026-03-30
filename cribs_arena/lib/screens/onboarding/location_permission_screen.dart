import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'term_agreement_screen.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';

class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

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
              imagePath: 'assets/images/map_pin.png',
              size: 60,
            ),
            const SizedBox(height: 24),
            const Text(
              'Allow Cribs’s Arena to access your location?',
              textAlign: TextAlign.center,
              style: kDialogTitleStyle,
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                DialogButton(
                  text: kAllowText,
                  onPressed: () async {
                    var status = await Permission.location.request();
                    if (status.isGranted) {
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } else if (status.isPermanentlyDenied) {
                      await openAppSettings();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pop(false); // Pop dialog after opening settings
                      }
                    } else {
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

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

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
                imagePath: 'assets/images/magnifier.png',
                size: 100,
              ),
              const SizedBox(height: 30),
              const Text(
                'FIND NEW PROPERTIES',
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
                'Sight houses wey dey near you\nJust on your location sharp sharp.\nWe go show you better options close by!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kBlack54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),
              PrimaryButton(
                text: 'Turn on location',
                onPressed: () async {
                  final granted = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const LocationPermissionDialog(),
                  );
                  if (granted == true && context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const TermAgreementScreen(),
                      ),
                    );
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
