import 'package:cribs_agents/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/auth_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:cribs_agents/provider/agent_provider.dart';
import 'package:provider/provider.dart';
import 'package:cribs_agents/utils/error_handler.dart';
import 'package:cribs_agents/screens/auth/widgets/area_selection_sheet.dart';

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
  final TextEditingController _areaController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAgentProfile();
    _retrieveLostData();
  }

  void _loadAgentProfile() {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    final agent = agentProvider.agent;

    if (agent != null) {
      _firstNameController.text = agent.firstName;
      _lastNameController.text = agent.lastName;
      _emailController.text = agent.email;
      _phoneController.text = agent.phone;
      _areaController.text = agent.area ?? '';
    }
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    super.dispose();
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
        _cropAndUploadImage(pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    }
  }

  Future<void> _cropAndUploadImage(XFile pickedFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
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

    if (croppedFile == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateProfilePicture(File(croppedFile.path));

      // Refresh provider
      if (mounted) {
        await Provider.of<AgentProvider>(context, listen: false)
            .fetchAgentProfile();

        if (!mounted) return;
        SnackbarHelper.showSuccess(
            context, 'Profile picture updated successfully',
            position: FlashPosition.bottom);
      }
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

  Future<String?> _showAreaSelectionBottomSheet(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return AreaSelectionBottomSheetContent(
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(title: Text('Edit Profile')),
      body: Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          if (agentProvider.isLoading && agentProvider.agent == null) {
            return const Center(child: CustomLoadingIndicator());
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
                    enabled: false, // Email usually cannot be changed easily
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
                    controller: _areaController,
                    label: 'Service Area',
                    hintText: kSignupSelectAreaHint,
                    readOnly: true,
                    enabled: !_isLoading,
                    onTap: () async {
                      final selectedArea = await _showAreaSelectionBottomSheet(
                        context,
                      );
                      if (selectedArea != null && mounted) {
                        setState(() {
                          _areaController.text = selectedArea;
                        });
                      }
                    },
                    suffixIcon: const Icon(Icons.arrow_drop_down),
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

  Widget _buildProfileImageSection() {
    return Center(
      child: Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          final agent = agentProvider.agent;
          debugPrint(
              'EditProfile: Raw profilePictureUrl: ${agent?.profilePictureUrl}');
          ImageProvider imageProvider;
          if (agent?.profilePictureUrl != null &&
              agent!.profilePictureUrl!.isNotEmpty &&
              agent.profilePictureUrl != 'default_profile.jpg') {
            String path = agent.profilePictureUrl!;
            if (path.startsWith('http')) {
              debugPrint('EditProfile: Using full URL');
              imageProvider = NetworkImage(path);
            } else {
              // Handle relative paths
              String cleanPath =
                  path.startsWith('/') ? path.substring(1) : path;

              if (cleanPath.startsWith('storage/')) {
                // already has storage/
              } else if (cleanPath.startsWith('agent_pictures/') ||
                  cleanPath.startsWith('profile_pictures/')) {
                cleanPath = 'storage/$cleanPath';
              } else {
                cleanPath = 'storage/agent_pictures/$cleanPath';
              }

              final url = '$kMainBaseUrl$cleanPath';
              debugPrint('EditProfile: Constructed URL: $url');
              imageProvider = NetworkImage(url);
            }
          } else {
            debugPrint('EditProfile: Using default asset');
            imageProvider =
                const AssetImage('assets/images/default_profile.jpg');
          }

          return ProfileAvatarWithBadge(
            imageProvider: imageProvider,
            radius: kRadius35,
            onBadgeTap: _showImagePickerOptions,
            badgeIcon: Icons.camera_alt,
            badgeColor: kPrimaryColor,
          );
        },
      ),
    );
  }

  Widget _buildSaveChangesButton() {
    return PrimaryButton(
      text: 'Save Changes',
      isLoading: _isLoading,
      onPressed: () async {
        setState(() {
          _isLoading = true;
        });

        try {
          await _authService.updateProfile(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            phone: _phoneController.text,
            area: _areaController.text,
          );

          if (!mounted) return;

          await Provider.of<AgentProvider>(context, listen: false)
              .fetchAgentProfile();

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
