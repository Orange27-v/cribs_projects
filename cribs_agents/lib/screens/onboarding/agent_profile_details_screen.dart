import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../services/agent_profile_service.dart';
import 'welcome_screen.dart';

class AgentProfileDetailsScreen extends StatefulWidget {
  const AgentProfileDetailsScreen({super.key});

  @override
  State<AgentProfileDetailsScreen> createState() =>
      _AgentProfileDetailsScreenState();
}

class _AgentProfileDetailsScreenState extends State<AgentProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceYearsController =
      TextEditingController();
  final TextEditingController _bookingFeesController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  String? _selectedGender;
  bool _isLicensed = false;
  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchAgentProfile();
  }

  Future<void> _fetchAgentProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final agentProfileService = AgentProfileService();
      final result = await agentProfileService.getAgentProfile();

      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          final data = result['data']['data'];
          if (data != null && data['agent_information'] != null) {
            final agentInfo = data['agent_information'];

            setState(() {
              _bioController.text = agentInfo['bio'] ?? '';
              _experienceYearsController.text =
                  (agentInfo['experience_years'] ?? '').toString();
              _bookingFeesController.text =
                  (agentInfo['booking_fees'] ?? '').toString();

              // Handle gender
              if (agentInfo['gender'] != null &&
                  _genderOptions.contains(agentInfo['gender'])) {
                _selectedGender = agentInfo['gender'];
                _genderController.text = _selectedGender ?? '';
              }

              // Handle licensed status (handle both boolean and int 0/1)
              if (agentInfo['is_licensed'] is bool) {
                _isLicensed = agentInfo['is_licensed'];
              } else if (agentInfo['is_licensed'] is int) {
                _isLicensed = agentInfo['is_licensed'] == 1;
              } else if (agentInfo['is_licensed'] is String) {
                _isLicensed = agentInfo['is_licensed'] == '1' ||
                    agentInfo['is_licensed'] == 'true';
              }

              // Handle profile image URL
              if (agentInfo['profile_picture_url'] != null) {
                _profileImageUrl = agentInfo['profile_picture_url'];
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error fetching profile: $e');
        // Optional: Show error snackbar or just fail silently since it's pre-filling
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _experienceYearsController.dispose();
    _bookingFeesController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      String path = _profileImageUrl!;

      // Check for default profile image
      if (path == 'default_profile.jpg' || path.contains('default_profile')) {
        return const AssetImage('assets/images/default_profile.jpg');
      }

      // Check if it's already a full URL
      if (path.startsWith('http')) {
        return NetworkImage(path);
      }

      // Remove leading slash if present
      String cleanPath = path.startsWith('/') ? path.substring(1) : path;

      // If path is just a filename (no slash), assume it's in agent_pictures
      if (!cleanPath.contains('/')) {
        cleanPath = 'agent_pictures/$cleanPath';
      }

      // If path already includes 'storage/', use it as is, otherwise add 'storage/'
      if (!cleanPath.startsWith('storage/')) {
        cleanPath = 'storage/$cleanPath';
      }

      // Construct the full URL
      String baseUrl = kMainBaseUrl;
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      String finalPath = cleanPath;
      if (finalPath.startsWith('/')) {
        finalPath = finalPath.substring(1);
      }

      final String fullImageUrl = '$baseUrl/$finalPath';
      debugPrint('✅ BottomNav - Constructed URL: $fullImageUrl');
      return NetworkImage(fullImageUrl);
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final agentProfileService = AgentProfileService();

      final result = await agentProfileService.updateAgentProfile(
        bio: _bioController.text.trim(),
        gender: _selectedGender,
        isLicensed: _isLicensed,
        experienceYears: int.tryParse(_experienceYearsController.text) ?? 0,
        bookingFees: double.tryParse(_bookingFeesController.text) ?? 0.0,
        profileImage: _profileImage,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to welcome screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showExperiencePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Years of Experience',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kBlack87,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 22, // 0 to 20, plus "20+"
                  itemBuilder: (context, index) {
                    String value = index == 21 ? '20+' : index.toString();
                    return ListTile(
                      title: Text(
                        '$value ${index == 1 ? 'Year' : 'Years'}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: _experienceYearsController.text == value
                              ? kPrimaryColor
                              : kBlack87,
                          fontWeight: _experienceYearsController.text == value
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _experienceYearsController.text = value;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Gender',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kBlack87,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: _genderOptions.map((String gender) {
                  return ListTile(
                    title: Text(
                      gender,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: _selectedGender == gender
                            ? kPrimaryColor
                            : kBlack87,
                        fontWeight: _selectedGender == gender
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedGender = gender;
                        _genderController.text = gender;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: const PrimaryAppBar(
        title: Text('Complete Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPaddingH24V16,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // Profile Picture
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                        backgroundImage: _getProfileImageProvider(),
                        child: (_profileImage == null &&
                                (_profileImageUrl == null ||
                                    _profileImageUrl!.isEmpty))
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: kPrimaryColor,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: kWhite,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to upload profile picture',
                  style: TextStyle(
                    color: kGrey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 32),

                // Bio
                CustomTextField(
                  controller: _bioController,
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself and your expertise...',
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your bio';
                    }
                    if (value.trim().length < 50) {
                      return 'Bio should be at least 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                GestureDetector(
                  onTap: _isLoading ? null : _showGenderPicker,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: _genderController,
                      readOnly: true,
                      labelText: 'Gender',
                      hintText: 'Select your gender',
                      prefixIcon: Icons.person_outline,
                      suffixIcon:
                          const Icon(Icons.arrow_drop_down, color: kGrey),
                      enabled: !_isLoading,
                      validator: (value) {
                        if (_selectedGender == null ||
                            _selectedGender!.isEmpty) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Experience Years
                GestureDetector(
                  onTap: _isLoading ? null : _showExperiencePicker,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: _experienceYearsController,
                      readOnly: true,
                      labelText: 'Years of Experience',
                      hintText: 'Select years of experience',
                      prefixIcon: Icons.work_outline,
                      suffixIcon:
                          const Icon(Icons.arrow_drop_down, color: kGrey),
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your years of experience';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Booking Fees
                CustomTextField(
                  controller: _bookingFeesController,
                  labelText: 'Booking Fees (₦)',
                  hintText: 'e.g., 5000 (max ₦10,000)',
                  prefixIcon: Icons.payments,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your booking fees';
                    }
                    final fees = double.tryParse(value);
                    if (fees == null || fees < 0) {
                      return 'Please enter a valid amount';
                    }
                    if (fees > 10000) {
                      return 'Booking fees cannot exceed ₦10,000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Licensed Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Are you a licensed real estate agent?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kBlack87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kLightBlue.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isLicensed = true;
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color:
                                      _isLicensed ? kWhite : Colors.transparent,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: _isLicensed
                                      ? [
                                          BoxShadow(
                                            color: kPrimaryColor.withValues(
                                                alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color:
                                          _isLicensed ? kPrimaryColor : kGrey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Yes',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: _isLicensed
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color:
                                            _isLicensed ? kPrimaryColor : kGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isLicensed = false;
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: !_isLicensed
                                      ? kWhite
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: !_isLicensed
                                      ? [
                                          BoxShadow(
                                            color: kPrimaryColor.withValues(
                                                alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_outlined,
                                      size: 18,
                                      color:
                                          !_isLicensed ? kPrimaryColor : kGrey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Not yet',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: !_isLicensed
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: !_isLicensed
                                            ? kPrimaryColor
                                            : kGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                PrimaryButton(
                  text: _isLoading ? 'Saving...' : 'Continue',
                  onPressed: _isLoading ? null : _handleSubmit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
