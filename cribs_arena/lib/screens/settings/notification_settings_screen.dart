import 'package:flutter/material.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/services/notification_settings_service.dart';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NotificationSettingsService _notificationService;
  bool _isLoading = true;
  Map<String, bool> _settings = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationSettingsService();
    _fetchSettings();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _notificationService.getNotificationSettings();

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _settings = result.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.error?.message ?? 'Failed to load settings.';
        _isLoading = false;
      });
      SnackbarHelper.showError(context, _errorMessage!,
          position: FlashPosition.bottom);
    }
  }

  Future<void> _toggleSetting(String key, bool value) async {
    if (!mounted) return;

    setState(() {
      _settings[key] = value; // Optimistic update
    });

    final result =
        await _notificationService.updateNotificationSetting(key, value);

    if (!mounted) return;

    if (result.isError) {
      // Revert optimistic update on error
      setState(() {
        _settings[key] = !value;
        _errorMessage = result.error?.message ?? 'Failed to update setting.';
      });
      SnackbarHelper.showError(context, _errorMessage!,
          position: FlashPosition.bottom);
    } else {
      SnackbarHelper.showInfo(context, 'Setting updated successfully!',
          position: FlashPosition.bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('Notification Settings'),
      ),
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        text: 'Retry',
                        onPressed: _fetchSettings,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildNotificationSwitch(
                      title: 'Push Notifications',
                      description: 'Receive general push notifications.',
                      settingKey: 'push_notifications_enabled',
                    ),
                    _buildNotificationSwitch(
                      title: 'New Messages',
                      description: 'Get notified about new chat messages.',
                      settingKey: 'new_messages_enabled',
                    ),
                    _buildNotificationSwitch(
                      title: 'New Listings',
                      description:
                          'Alerts for new properties matching your preferences.',
                      settingKey: 'new_listings_enabled',
                    ),
                    _buildNotificationSwitch(
                      title: 'Price Changes',
                      description:
                          'Updates on price changes for saved properties.',
                      settingKey: 'price_changes_enabled',
                    ),
                    _buildNotificationSwitch(
                      title: 'App Updates & News',
                      description:
                          'Receive important announcements and app news.',
                      settingKey: 'app_updates_enabled',
                    ),
                  ],
                ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String description,
    required String settingKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CardContainer(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: kFontSize16,
                      fontWeight: FontWeight.w500,
                      color: kBlack87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: kFontSize12,
                      color: kGrey600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _settings[settingKey] ?? false,
              onChanged: (bool value) {
                _toggleSetting(settingKey, value);
              },
              activeThumbColor: kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
