import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io'; // For File
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/utils/error_handler.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _userProfileFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _loadUserProfile();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    final LostDataResponse response = await ImagePicker().retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      await _cropAndUploadImage(response.file!);
    }
  }

  Future<Map<String, dynamic>> _loadUserProfile() async {
    try {
      final userProfileData = await _userService.getUserProfile();

      // Backend returns user data in 'data' key, not 'user'
      final userData = userProfileData['data'];

      if (userData == null) {
        throw Exception('User data not found in response');
      }

      // Populate controllers with data from backend
      _firstNameController.text = userData['first_name'] ?? '';
      _lastNameController.text = userData['last_name'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _locationController.text = userData['area'] ?? '';

      return userProfileData;
    } catch (e) {
      // Rethrow the error to be caught by the FutureBuilder
      throw Exception('Failed to load profile. Please try again. $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _userService.dispose();
    super.dispose();
  }

  Future<void> _cropAndUploadImage(XFile pickedFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
    );

    if (croppedFile == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _userService.updateUserProfile(
        name: '${_firstNameController.text} ${_lastNameController.text}',
        phone: _phoneController.text,
        location: _locationController.text,
        imageFile: File(croppedFile.path),
      );

      if (response['data'] != null) {
        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(response['data']);
      }

      if (!mounted) return;
      SnackbarHelper.showSuccess(
          context, 'Profile picture updated successfully',
          position: FlashPosition.bottom);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      if (!mounted) return;
      SnackbarHelper.showError(
          context, 'You must be logged in to update your profile picture.',
          position: FlashPosition.bottom);
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) return;

      await _cropAndUploadImage(pickedFile);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('Edit Profile'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: CardContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CardContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No profile data found.',
                      textAlign: TextAlign.center),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: kPaddingAll16,
            child: CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileImageSection(),
                  const SizedBox(height: kSizedBoxH24),
                  Row(
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hintText: 'First Name',
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: kSizedBoxW16),
                      Expanded(
                        child: LabeledTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hintText: 'Last Name',
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSizedBoxH16),
                  LabeledTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'Enter your email address',
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: kSizedBoxH16),
                  LabeledTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hintText: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: kSizedBoxH16),
                  LabeledTextField(
                    controller: _locationController,
                    label: 'Location',
                    hintText: 'Enter your location',
                  ),
                  const SizedBox(height: kSizedBoxH24),
                  _buildSaveChangesButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ImageProvider _getProfileImageProvider(dynamic user) {
    if (user == null) {
      return const AssetImage('assets/images/default_profile.jpg');
    }

    final String? profilePicturePath = user['profile_picture_url'];

    if (profilePicturePath != null &&
        profilePicturePath.isNotEmpty &&
        profilePicturePath != 'default_profile.jpg') {
      if (profilePicturePath.startsWith('http')) {
        return NetworkImage(profilePicturePath);
      }
      // Remove leading slash if present and ensure proper URL construction
      String cleanPath = profilePicturePath.startsWith('/')
          ? profilePicturePath.substring(1)
          : profilePicturePath;

      // If path already includes 'storage/', use it as is, otherwise add 'storage/'
      if (!cleanPath.startsWith('storage/')) {
        cleanPath = 'storage/$cleanPath';
      }

      final String fullImageUrl =
          cleanPath.startsWith('http') ? cleanPath : '$kMainBaseUrl$cleanPath';
      return NetworkImage(fullImageUrl);
    }
    return const AssetImage('assets/images/default_profile.jpg');
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickAndUploadImage,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.user;
                return CircleAvatar(
                  radius: kRadius35,
                  backgroundImage: _getProfileImageProvider(user),
                );
              },
            ),
            Positioned(
              bottom: -5,
              right: -5,
              child: Container(
                padding: kPaddingAll4,
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    color: kWhite, size: kIconSize16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveChangesButton() {
    return PrimaryButton(
      text: 'Save Changes',
      isLoading: _isLoading,
      onPressed: () async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user == null) return;
        setState(() {
          _isLoading = true;
        });
        try {
          final response = await _userService.updateUserProfile(
            name: '${_firstNameController.text} ${_lastNameController.text}',
            phone: _phoneController.text,
            location: _locationController.text,
            imageFile: null,
          );

          if (response['data'] != null) {
            userProvider.setUser(response['data']);
          }

          if (!mounted) return;
          SnackbarHelper.showSuccess(context, 'Profile updated successfully',
              position: FlashPosition.bottom);
        } catch (e) {
          if (!mounted) return;
          SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
              position: FlashPosition.bottom);
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }
}
