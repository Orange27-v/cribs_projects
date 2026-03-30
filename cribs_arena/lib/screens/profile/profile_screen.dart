import 'dart:async';

import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:cribs_arena/screens/auth/login_screen.dart';
import 'package:cribs_arena/screens/schedule/schedule_screen.dart';
import 'package:cribs_arena/screens/account/edit_profile_screen.dart';
import 'package:cribs_arena/screens/account/change_password_screen.dart';
import 'package:cribs_arena/screens/account/account_verification.dart';
import 'package:cribs_arena/screens/settings/notification_settings_screen.dart';
import 'package:cribs_arena/screens/settings/location_settings_screen.dart';
import 'package:cribs_arena/screens/legal/terms_of_service_screen.dart';
import 'package:cribs_arena/screens/legal/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_arena/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:cribs_arena/services/user_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:cribs_arena/services/user_service.dart';
import 'package:cribs_arena/services/inspection_service.dart';
import 'package:cribs_arena/utils/error_handler.dart';

import 'package:cribs_arena/widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final UserAuthService authService = UserAuthService();
  final UserService _userService = UserService();
  final InspectionService _inspectionService = InspectionService();
  int _upcomingInspections = 0;

  late final StreamSubscription<int> _inspectionCountSubscription;

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
    // Listen to the real-time stream instead of fetching once
    _inspectionCountSubscription =
        _inspectionService.getUpcomingInspectionsCountStream().listen((count) {
      if (mounted) {
        setState(() {
          _upcomingInspections = count;
        });
      }
    });
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

  @override
  void dispose() {
    _inspectionCountSubscription
        .cancel(); // cancel the stream to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

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
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : user == null
              ? NetworkErrorWidget(
                  errorMessage: 'Unable to load profile data',
                  title: 'Profile Unavailable',
                  icon: Icons.person_outline,
                  onRefresh: _refreshUserData,
                )
              : CustomRefreshIndicator(
                  onRefresh: _refreshUserData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildProfileHeader(context, user),
                        const SizedBox(height: kSizedBoxH24),
                        _buildOptionList(user),
                        const SizedBox(height: 24),
                        _buildSignOutButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _refreshUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final userData = await authService.fetchUserData();
      if (mounted) {
        userProvider.setUser(userData['data']);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return CardContainer(
      child: Row(
        children: [
          _buildProfileImage(user),
          const SizedBox(width: 16),
          Expanded(
            child: _buildProfileInfo(user),
          ),
          _buildCalendarIcon(context, _upcomingInspections),
        ],
      ),
    );
  }

  Widget _buildProfileImage(dynamic user) {
    final String? profilePictureUrl = user?['profile_picture_url'];
    return ProfileAvatarWithBadge(
      imageProvider: getResolvedImageProvider(profilePictureUrl),
      radius: kRadius35,
      onBadgeTap: _showImagePickerOptions,
      badgeIcon: Icons.camera_alt,
      badgeColor: kPrimaryColor,
    );
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
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      _cropImage(File(pickedFile.path));
    }
  }

  Future<void> _cropImage(File imageFile) async {
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
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) {
        throw Exception('User data not available for profile update.');
      }

      final response = await _userService.updateUserProfile(
        imageFile: File(croppedFile.path),
      );

      if (!mounted) return;

      if (response['data'] != null) {
        userProvider.setUser(response['data']);
      }

      if (!mounted) return;
      SnackbarHelper.showSuccess(
          context, 'Profile picture updated successfully',
          position: FlashPosition.bottom);
    } catch (e, stackTrace) {
      // Detailed debug logging
      debugPrint('❌ Error updating profile picture');
      debugPrint('🔴 Error type: ${e.runtimeType}');
      debugPrint('🔴 Error message: $e');
      debugPrint('📚 Stack trace:');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      SnackbarHelper.showError(context, getErrorMessage(e),
          position: FlashPosition.bottom);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileInfo(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user['full_name'] ?? 'User Name',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user['email'] ?? 'email@example.com',
          style: GoogleFonts.roboto(color: kGrey, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          _formatMemberSince(user['created_at']),
          style: GoogleFonts.roboto(color: kGrey, fontSize: 12),
        ),
      ],
    );
  }

  String _formatMemberSince(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) {
      return 'Member since 2023'; // FIXED: Handle null properly
    }
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Member since 2023'; // FIXED: Consistent fallback
      }
      return 'Member since ${DateFormat('MMMM yyyy').format(date)}';
    } catch (_) {
      return 'Member since 2023'; // FIXED: Consistent fallback
    }
  }

  Widget _buildCalendarIcon(BuildContext context, int inspectionCount) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyScheduleScreen(),
          ),
        );
      },
      child: Container(
        padding: kPaddingAll12,
        decoration: const BoxDecoration(
          color: kLightBlue,
          borderRadius: kRadius12,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset('assets/icons/calender.svg',
                colorFilter:
                    const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                width: 28,
                height: 28),
            if (inspectionCount > 0)
              Positioned(
                top: kTopNeg15,
                right: -12,
                child: Container(
                  padding: kPaddingAll8,
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    inspectionCount.toString(),
                    style: const TextStyle(
                        color: kWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionList(dynamic user) {
    final userProvider = Provider.of<UserProvider>(context);
    return Column(
      children: [
        _buildSection(
          'ACCOUNT',
          [
            OptionTile(
              svgPath: 'assets/icons/finger_print.svg',
              title: 'Account Verification',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountVerificationScreen()),
                );
              },
              trailing: userProvider.isVerified
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
                      builder: (context) => const EditProfileScreen()),
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
                      builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          'SETTINGS',
          [
            OptionTile(
              svgPath: 'assets/icons/notification.svg',
              title: 'Notification settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen()),
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
                      builder: (context) => const LocationSettingsScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          'LEGAL',
          [
            OptionTile(
              svgPath: 'assets/icons/file-narrow.svg',
              title: 'Terms of Service',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen()),
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
                      builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),
          ],
        ),
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
            blurRadius: 6,
            offset: const Offset(0, 2),
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

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

    setState(() => _isLoading = true);

    try {
      await authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      userProvider.clearUser();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
}
