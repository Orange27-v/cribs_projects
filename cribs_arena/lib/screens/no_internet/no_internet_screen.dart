import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';

/// A dedicated screen shown when there's no internet connection
/// This screen is shown forcefully when connectivity is lost
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: kPaddingAll24,
              child: CardContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon Container
                    Container(
                      decoration: BoxDecoration(
                        color: kCircleBg.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: kCircleBoxShadow,
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 64,
                        color: kPrimaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'No Internet Connection',
                      style: TextStyle(
                        fontSize: kFontSize20,
                        fontWeight: FontWeight.bold,
                        color: kDarkTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'It looks like you\'re offline. Please check your internet connection and try again.',
                      style: TextStyle(
                        fontSize: kFontSize14,
                        color: kGrey600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Troubleshooting Tips
                    CardContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Troubleshooting Tips:',
                            style: TextStyle(
                              fontSize: kFontSize14,
                              fontWeight: FontWeight.w500,
                              color: kDarkTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTipItem(
                            icon: Icons.wifi,
                            text: 'Check if Wi-Fi or mobile data is turned on',
                          ),
                          const SizedBox(height: 8),
                          _buildTipItem(
                            icon: Icons.airplanemode_active,
                            text: 'Make sure Airplane mode is off',
                          ),
                          const SizedBox(height: 8),
                          _buildTipItem(
                            icon: Icons.router,
                            text: 'Try restarting your router',
                          ),
                          const SizedBox(height: 8),
                          _buildTipItem(
                            icon: Icons.refresh,
                            text: 'Move to an area with better signal',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: kRadius8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: kPrimaryColor,
                            size: kIconSize16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'The app will automatically reconnect when your internet is restored.',
                              style: TextStyle(
                                fontSize: kFontSize12,
                                color: kPrimaryColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: kIconSize16,
          color: kPrimaryColor,
        ),
        SizedBox(width: kSizedBoxW12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: kFontSize12,
              color: kGrey600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
