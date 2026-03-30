import 'dart:async';
import 'package:cribs_agents/screens/auth/login_screen.dart';
import 'package:cribs_agents/services/auth_service.dart';
import 'package:cribs_agents/services/agent_inspection_service.dart';
import 'package:cribs_agents/screens/schedule/schedule_screen.dart';
import 'package:cribs_agents/screens/account/edit_profile_screen.dart';
import 'package:cribs_agents/screens/account/change_password_screen.dart';
import 'package:cribs_agents/screens/account/account_verification.dart';
import 'package:cribs_agents/screens/settings/notification_settings_screen.dart';
import 'package:cribs_agents/screens/settings/location_settings_screen.dart';
import 'package:cribs_agents/screens/legal/terms_of_service_screen.dart';
import 'package:cribs_agents/screens/legal/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cribs_agents/provider/agent_provider.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/utils/snackbar_helper.dart';
import 'package:cribs_agents/utils/error_handler.dart';
import 'package:flash/flash.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isAgent = true; // true for Agent, false for Landlord
  // ignore: unused_field
  final bool _isProfileVerified = true;
  final AuthService authService = AuthService();
  final AgentInspectionService _inspectionService = AgentInspectionService();
  bool _isLoading = false;
  int _upcomingInspections = 0;
  late final StreamSubscription<int> _inspectionCountSubscription;

  @override
  void initState() {
    super.initState();
    // Fetch agent profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().fetchAgentProfile();
    });
    _retrieveLostData();

    // Listen to the real-time stream
    _inspectionCountSubscription =
        _inspectionService.getUpcomingInspectionsCountStream().listen((count) {
      if (mounted) {
        setState(() {
          _upcomingInspections = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _inspectionCountSubscription.cancel();
    super.dispose();
  }

  Future<void> _retrieveLostData() async {
    final LostDataResponse response = await ImagePicker().retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      _cropImage(File(response.file!.path));
    }
  }

  void _showImagePickerOptions() {
    CustomBottomSheet.show(
      context: context,
      initialChildSize: 0.25,
      maxChildSize: 0.3,
      minChildSize: 0.2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: kPrimaryColor),
            title: const Text('Photo Library'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera, color: kPrimaryColor),
            title: const Text('Camera'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        _cropImage(File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    }
  }

  Future<void> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: kPrimaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      if (croppedFile == null) return;

      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      await authService.updateProfilePicture(File(croppedFile.path));

      // Refresh provider
      if (mounted) {
        await context.read<AgentProvider>().fetchAgentProfile();
        if (mounted) {
          SnackbarHelper.showSuccess(
              context, 'Profile picture updated successfully',
              position: FlashPosition.bottom);
        }
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: GoogleFonts.roboto(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          // If manually loading (image upload) or provider is loading initial data
          if (_isLoading ||
              (agentProvider.isLoading && agentProvider.agent == null)) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (agentProvider.error != null && agentProvider.agent == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      agentProvider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(color: kGrey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 120,
                    child: PrimaryButton(
                      text: 'Retry',
                      onPressed: () => agentProvider.fetchAgentProfile(),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomRefreshIndicator(
            onRefresh: () => agentProvider.refreshProfile(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileHeader(context, agentProvider.agent),
                  const SizedBox(height: kSizedBoxH24),
                  _buildOptionList(agentProvider),
                  const SizedBox(height: 24),
                  _buildSignOutButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Agent? agent) {
    return CardContainer(
      child: Row(
        children: [
          _buildProfileImage(agent?.profilePictureUrl),
          const SizedBox(width: 16),
          Expanded(
            child: _buildProfileInfo(agent),
          ),
          _buildCalendarIcon(context),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? profilePictureUrl) {
    debugPrint('ProfileScreen: Raw profilePictureUrl: $profilePictureUrl');

    return ProfileAvatarWithBadge(
      imageProvider: getResolvedImageProvider(profilePictureUrl),
      radius: kRadius35,
      onBadgeTap: _showImagePickerOptions,
      badgeIcon: Icons.camera_alt,
      badgeColor: kPrimaryColor,
    );
  }

  Widget _buildProfileInfo(Agent? agent) {
    final memberSince = agent?.createdAt != null
        ? DateFormat('MMMM yyyy').format(agent!.createdAt!)
        : 'Recently';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          agent?.fullName ?? "Loading...",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isAgent ? 'Agent' : 'Landlord',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Member since $memberSince',
          style: GoogleFonts.roboto(
            color: kGrey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarIcon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyScheduleScreen()),
        );
      },
      child: Container(
        padding: kPaddingAll12,
        decoration: const BoxDecoration(
          color: kLightBlue,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              'assets/icons/calender.svg',
              colorFilter: const ColorFilter.mode(
                kPrimaryColor,
                BlendMode.srcIn,
              ),
              width: 28,
              height: 28,
            ),
            if (_upcomingInspections > 0)
              Positioned(
                top: -15,
                right: -12,
                child: Container(
                  padding: kPaddingAll8,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_upcomingInspections',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionList(AgentProvider agentProvider) {
    // Determine if verified based on agent data
    // Assuming agent.key or some field determines verification, for now using local var or provider check if available
    // But earlier code used _isProfileVerified (hardcoded true).
    // Let's assume we want to show it if verified.
    // For now, I'll keep the logic simple or just show verified if we want.
    // The previous code had: trailing: _isProfileVerified ? ...
    // Let's us agentProvider.agent?.isVerified ?? false if that exists, or keep hardcoded for now if model doesn't support it yet.
    // Checking Agent model... I don't see it in my memory. I'll stick to _isProfileVerified for now but better to use agent data.

    return Column(
      children: [
        _buildSection('ACCOUNT', [
          OptionTile(
            svgPath: 'assets/icons/finger_print.svg',
            title: 'Account Verification',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountVerificationScreen(),
                ),
              );
            },
            trailing: agentProvider.isVerified
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VerifiedBadge(),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/icons/arrow_forward_ios.svg',
                        colorFilter:
                            const ColorFilter.mode(kGrey, BlendMode.srcIn),
                        width: 16,
                        height: 16,
                      ),
                    ],
                  )
                : null,
          ),
          OptionTile(
            svgPath: 'assets/icons/profile_user.svg',
            title: 'Update Account Details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          OptionTile(
            svgPath: 'assets/icons/lock.svg',
            title: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('SETTINGS', [
          OptionTile(
            svgPath: 'assets/icons/notification.svg',
            title: 'Notification settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          OptionTile(
            svgPath: 'assets/icons/map-square.svg',
            title: 'Location settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationSettingsScreen(),
                ),
              );
            },
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('LEGAL', [
          OptionTile(
            svgPath: 'assets/icons/file-narrow.svg',
            title: 'Terms of Service',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          OptionTile(
            svgPath: 'assets/icons/shield.svg',
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) SectionHeader(title: title),
        Column(
          children: List.generate(children.length, (index) {
            return Column(
              children: [
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      height: kSizedBoxH48,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _handleSignOut,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/logout.svg',
              colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Sign out',
              style: GoogleFonts.roboto(
                color: kBlack,
                fontWeight: FontWeight.w500,
                fontSize: kFontSize14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CustomAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await authService.logout();
      if (!mounted) return;
      agentProvider.clearAgent();

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    }
  }
}
