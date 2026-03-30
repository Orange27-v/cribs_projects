import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cribs_agents/services/firebase_messaging_service.dart';
import 'package:cribs_agents/main.dart' show navigatorKey;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Import for TapGestureRecognizer
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../widgets/widgets.dart'; // Import the updated widgets file
import 'login_screen.dart'; // Import login screen for navigation
import 'package:cribs_agents/services/auth_service.dart';
import 'widgets/area_selection_sheet.dart';
import 'widgets/role_selection_sheet.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final AuthService authService = AuthService();
  String? _selectedArea;
  String? _selectedRole;
  double? _latitude;

  double? _longitude;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them to continue.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    return true;
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      // Check location permission and status
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission || !mounted) return;

      if (_selectedArea == null || _selectedArea!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(kSelectAreaText),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (_selectedRole == null || _selectedRole!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a role'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing Data'),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        // Step 1: Get coordinates from device location
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        _latitude = position.latitude;
        _longitude = position.longitude;

        // Get FCM Token
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessagingService(navigatorKey)
                  .getStoredFCMToken() ??
              await FirebaseMessaging.instance.getToken();
        } catch (e) {
          debugPrint('Error getting FCM token: $e');
        }

        if (!mounted) return;

        final String platform = Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'unknown';

        // Register user with backend
        var registerResponse = await authService.register(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: '+234${_phoneController.text}',
          area: _selectedArea!,
          role: _selectedRole!.toLowerCase(),
          latitude: _latitude ?? 0.0,
          longitude: _longitude ?? 0.0,
          password: _passwordController.text,
          fcmToken: fcmToken,
          platform: platform,
        );

        if (registerResponse.statusCode >= 200 &&
            registerResponse.statusCode < 300) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registration successful! Please verify your email.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
            // Redirect to email verification screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: _emailController.text.trim(),
                ),
              ),
            );
          }
        } else {
          final responseBody = jsonDecode(registerResponse.body);
          throw Exception(responseBody['message'] ?? 'Registration failed');
        }
      } catch (e) {
        debugPrint('Signup error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(kSignupFillAllFieldsError),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPaddingH24V16, // Using constant padding
          child: Form(
            // Wrap with Form for validation
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AuthTopBar(
                  // Reusable top bar
                  buttonText: kSignInText,
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const AuthHeader(title: 'Create Account'),
                const SizedBox(height: 20), // Reusable logo and avatar
                // Responsive layout for first and last name
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use Column layout on small screens (< 360px width)
                    final bool useColumnLayout = constraints.maxWidth < 360;

                    if (useColumnLayout) {
                      return Column(
                        children: [
                          CustomTextField(
                            controller: _firstNameController,
                            hintText: kSignupFirstNameHint,
                            prefixIcon: Icons.person,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _lastNameController,
                            hintText: kSignupLastNameHint,
                            prefixIcon: Icons.person,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    }

                    // Use Row layout on larger screens
                    return Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            hintText: kSignupFirstNameHint,
                            prefixIcon: Icons.person,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            hintText: kSignupLastNameHint,
                            prefixIcon: Icons.person,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                        border: Border.all(color: kGrey.shade300, width: 1.5),
                      ),
                      child: const Text(
                        '+234',
                        style: TextStyle(
                          fontSize: 16,
                          color: kBlack,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: kSignupPhoneNumberLabel,
                          labelStyle: const TextStyle(
                            color: kBlack54,
                            fontSize: 16,
                          ),
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(
                            color: kGrey.shade400,
                            fontSize: 16,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: BorderSide(
                              color: kPrimaryColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: BorderSide(
                              color: kGrey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: BorderSide(
                              color: kPrimaryColor,
                              width: 2.0,
                            ),
                          ),
                          errorBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 2.0,
                            ),
                          ),
                          contentPadding: const EdgeInsets.only(
                            top: 18,
                            bottom: 18,
                            left: 10,
                            right: 10,
                          ),
                          filled: true,
                          fillColor: kWhite,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          color: kBlack,
                        ),
                        cursorColor: kPrimaryColor,
                        onChanged: (value) {
                          if (value.startsWith('0')) {
                            _phoneController.text = value.substring(1);
                            _phoneController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                offset: _phoneController.text.length,
                              ),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.length != 10) {
                            return 'Phone number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _roleController,
                  hintText: 'I am an...',
                  prefixIcon: Icons.person_pin_circle_outlined,
                  readOnly: true,
                  enabled: !_isLoading,
                  onTap: () async {
                    final selectedRole = await _showRoleSelectionBottomSheet(
                      context,
                    );
                    if (selectedRole != null && mounted) {
                      setState(() {
                        _selectedRole = selectedRole;
                        _roleController.text = selectedRole;
                      });
                    }
                  },
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  filled: _selectedRole != null,
                  fillColor: _selectedRole != null ? Colors.blue.shade50 : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _areaController,
                  hintText: kSignupSelectAreaHint,
                  readOnly: true,
                  enabled: !_isLoading,
                  onTap: () async {
                    final selectedArea = await _showAreaSelectionBottomSheet(
                      context,
                    );
                    if (selectedArea != null && mounted) {
                      setState(() {
                        _selectedArea = selectedArea;
                        _areaController.text = selectedArea;
                      });
                    }
                  },
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  prefixIcon: Icons.location_on,
                  filled: _selectedArea != null,
                  fillColor: _selectedArea != null ? Colors.blue.shade50 : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return kSelectAreaText;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  hintText: kSignupVerifiableEmailHint,
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomPasswordField(
                  controller: _passwordController,
                  labelText: kSignupPasswordHint,
                  hintText: kSignupPasswordHint,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain at least one uppercase letter';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }
                    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
                      return 'Password must contain at least one special character';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                PrimaryButton(
                    text: kContinueText,
                    onPressed: _isLoading ? null : _handleSignup,
                    isLoading: _isLoading),

                const SizedBox(height: 20),

                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: kSignInText,
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AuthDisclaimerText(
        text: 'By continuing, you agree to our',
        linkText: 'Terms of Service and Privacy Policy',
        onLinkTap: () async {
          final Uri url = Uri.parse('https://cribsarena.com/terms');
          if (!await launchUrl(url)) {
            debugPrint('Could not launch $url');
          }
        },
      ), // Reusable disclaimer text
    );
  }

  Future<String?> _showRoleSelectionBottomSheet(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return RoleSelectionBottomSheetContent(
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  Future<String?> _showAreaSelectionBottomSheet(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
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
}
