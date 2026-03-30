import 'package:flutter/material.dart';
import 'package:cribs_arena/screens/components/custom_app_bar.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _isPrivateAccount = false;
  bool _enableLocationServices = true;
  bool _enableTwoFactorAuth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const CustomAppBar(
        title: 'Privacy & Security',
      ),
      body: SingleChildScrollView(
        padding: kPaddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Privacy',
              padding: EdgeInsets.zero,
              textStyle: GoogleFonts.roboto(
                fontSize: kFontSize18,
                fontWeight: FontWeight.bold,
                color: kBlack,
              ),
            ),
            const SizedBox(height: kSizedBoxH24),
            _buildSettingTile(
              title: 'Private Account',
              subtitle: 'Make your account private',
              trailing: Switch(
                value: _isPrivateAccount,
                onChanged: (value) {
                  setState(() {
                    _isPrivateAccount = value;
                  });
                },
                activeThumbColor: kPrimaryColor,
              ),
            ),
            const SizedBox(height: kSizedBoxH12),
            _buildSettingTile(
              title: 'Location Services',
              subtitle: 'Allow app to access your location',
              trailing: Switch(
                value: _enableLocationServices,
                onChanged: (value) {
                  setState(() {
                    _enableLocationServices = value;
                  });
                },
                activeThumbColor: kPrimaryColor,
              ),
            ),
            const SizedBox(height: kSizedBoxH24),
            SectionHeader(
              title: 'Security',
              padding: EdgeInsets.zero,
              textStyle: GoogleFonts.roboto(
                fontSize: kFontSize18,
                fontWeight: FontWeight.bold,
                color: kBlack,
              ),
            ),
            const SizedBox(height: kSizedBoxH24),
            _buildSettingTile(
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              trailing: Switch(
                value: _enableTwoFactorAuth,
                onChanged: (value) {
                  setState(() {
                    _enableTwoFactorAuth = value;
                  });
                },
                activeThumbColor: kPrimaryColor,
              ),
            ),
            const SizedBox(height: kSizedBoxH12),
            _buildSettingTile(
              title: 'Manage Devices',
              subtitle: "See where you're logged in",
              onTap: () {
                // Navigate to manage devices screen
                debugPrint('Manage Devices tapped');
              },
            ),
            const SizedBox(height: kSizedBoxH12),
            _buildSettingTile(
              title: 'Download Your Data',
              subtitle: 'Get a copy of your account data',
              onTap: () {
                // Handle download data
                debugPrint('Download Your Data tapped');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: kPaddingH16V12,
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kRadius12,
          boxShadow: [
            BoxShadow(
              color: kBlackOpacity005,
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize16,
                      fontWeight: FontWeight.w500,
                      color: kBlack,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: kSizedBoxH4),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: kFontSize12,
                        color: kGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              const Icon(Icons.arrow_forward_ios,
                  size: kIconSize16, color: kGrey),
          ],
        ),
      ),
    );
  }
}
