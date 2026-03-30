import 'package:cribs_arena/screens/auth/login_screen.dart';
import 'package:cribs_arena/services/user_auth_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cribs_arena/services/firebase_messaging_service.dart';
import 'package:cribs_arena/main.dart' show navigatorKey;

import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/snackbar_helper.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import '../../services/nigerian_states_service.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserAuthService authService = UserAuthService();
  String? _selectedArea;
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
    super.dispose();
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Location services are disabled. Please enable them to continue.',
          position: FlashPosition.bottom,
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'Location permissions are denied.',
            position: FlashPosition.bottom,
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Location permissions are permanently denied, we cannot request permissions.',
          position: FlashPosition.bottom,
        );
      }
      return false;
    }

    return true;
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      SnackbarHelper.showError(context, kSignupFillAllFieldsError,
          position: FlashPosition.bottom);
      return;
    }

    // Check location permission and status
    bool hasPermission = await _checkLocationPermission();
    if (!hasPermission || !mounted) return;

    if (_selectedArea == null || _selectedArea!.trim().isEmpty) {
      if (!mounted) return;
      SnackbarHelper.showError(context, kSelectAreaText,
          position: FlashPosition.bottom);
      return;
    }

    // Prevent multiple submissions
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;
    SnackbarHelper.showInfo(context, 'Creating your account...',
        position: FlashPosition.bottom);

    try {
      // Step 1: Get coordinates from device location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Get FCM Token
      String? fcmToken;
      try {
        fcmToken =
            await FirebaseMessagingService(navigatorKey).getStoredFCMToken() ??
                await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'unknown';

      // Step 2: Register user with backend
      var registerResponse = await authService.registrationService.register(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: '+234${_phoneController.text}',
        area: _selectedArea!,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        password: _passwordController.text,
        fcmToken: fcmToken,
        platform: platform,
      );

      if (registerResponse.statusCode < 200 ||
          registerResponse.statusCode >= 300) {
        debugPrint(
            'Backend registration failed with status: ${registerResponse.statusCode}');
        debugPrint('Response body: ${registerResponse.body}');
        final responseBody = jsonDecode(registerResponse.body);

        // Handle validation errors
        if (responseBody['errors'] != null) {
          String errorMsg = '';
          Map<String, dynamic> errors = responseBody['errors'];
          errors.forEach((key, value) {
            if (value is List) {
              errorMsg += '${value.join(", ")}\n';
            } else {
              errorMsg += '$value\n';
            }
          });
          throw Exception(errorMsg.trim());
        }

        throw Exception(
            responseBody['message'] ?? 'Backend registration failed');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SnackbarHelper.showSuccess(
        context,
        'Registration successful! Please log in.',
        position: FlashPosition.bottom,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: _emailController.text.trim(),
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Signup error: $e');
      if (!mounted) return;
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      SnackbarHelper.showError(context, errorMessage,
          position: FlashPosition.bottom);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kPaddingH24V16,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AuthTopBar(
                  buttonText: kSignInText,
                  onButtonPressed: () {
                    if (_isLoading) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const AuthHeader(title: 'Create Account'),
                const SizedBox(height: 20),
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
                              if (value == null || value.trim().isEmpty) {
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
                              if (value == null || value.trim().isEmpty) {
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
                              if (value == null || value.trim().isEmpty) {
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
                              if (value == null || value.trim().isEmpty) {
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
                          horizontal: 12, vertical: 17),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8)),
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
                                right: Radius.circular(8)),
                            borderSide:
                                BorderSide(color: kPrimaryColor, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(8)),
                            borderSide:
                                BorderSide(color: kGrey.shade300, width: 1.5),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(8)),
                            borderSide:
                                BorderSide(color: kPrimaryColor, width: 2.0),
                          ),
                          errorBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(8)),
                            borderSide:
                                BorderSide(color: Colors.red, width: 1.5),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(8)),
                            borderSide:
                                BorderSide(color: Colors.red, width: 2.0),
                          ),
                          contentPadding: const EdgeInsets.only(
                              top: 18, bottom: 18, left: 10, right: 10),
                          filled: true,
                          fillColor: kWhite,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10)
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
                                TextSelection.fromPosition(TextPosition(
                                    offset: _phoneController.text.length));
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
                  controller: TextEditingController(text: _selectedArea ?? ''),
                  hintText: kSignupSelectAreaHint,
                  readOnly: true,
                  enabled: !_isLoading,
                  onTap: _isLoading
                      ? null
                      : () async {
                          final selectedArea =
                              await _showAreaSelectionBottomSheet(context);
                          if (selectedArea != null) {
                            setState(() {
                              _selectedArea = selectedArea;
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
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
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
                      return 'Password must be at least 8 characters';
                    }

                    // Check for uppercase letter
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Password must contain at least one uppercase letter';
                    }

                    // Check for lowercase letter
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Password must contain at least one lowercase letter';
                    }

                    // Check for number
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }

                    // Check for special character
                    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                      return 'Password must contain at least one special character';
                    }

                    // Check for repeating characters (no more than 2 consecutive same characters)
                    if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
                      return 'Password cannot have more than 2 consecutive same characters';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: _isLoading ? 'Creating Account...' : kContinueText,
                  onPressed: _isLoading ? null : _handleSignup,
                ),
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
                          ..onTap = _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
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
        onLinkTap: () {
          // TODO: implement tap
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
          return _AreaSelectionBottomSheetContent(
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _AreaSelectionBottomSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const _AreaSelectionBottomSheetContent({
    required this.scrollController,
  });

  @override
  State<_AreaSelectionBottomSheetContent> createState() =>
      _AreaSelectionBottomSheetContentState();
}

class _AreaSelectionBottomSheetContentState
    extends State<_AreaSelectionBottomSheetContent> {
  late TextEditingController _searchController;
  List<Map<String, String>> _filteredStates = [];
  String? _currentSelectedArea;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filterStates('');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStates(_searchController.text);
  }

  void _filterStates(String query) {
    setState(() {
      _filteredStates = NigerianStatesService.searchStates(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: kPaddingAll24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              controller: widget.scrollController,
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: kGrey.shade300,
                      borderRadius: kRadius10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Image(
                    image: AssetImage('assets/images/map_pin.png'),
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    kSelectYourAreaTitle,
                    textAlign: TextAlign.center,
                    style: kDialogTitleStyle,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    kSelectAreaText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kBlack54,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _searchController,
                  labelText: kSearchAreaHint,
                  hintText: kSearchAreaExampleHint,
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 16),
                ..._filteredStates.map((state) => Column(
                      children: [
                        _AreaItem(
                          title: state['title']!,
                          subtitle: state['subtitle']!,
                          selected: _currentSelectedArea == state['title'],
                          onTap: () {
                            setState(() {
                              _currentSelectedArea = state['title'];
                            });
                          },
                        ),
                        const Divider(height: 1, color: kGrey),
                      ],
                    )),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentSelectedArea != null
                  ? () {
                      Navigator.pop(context, _currentSelectedArea);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: kPaddingV16,
                shape: const RoundedRectangleBorder(
                  borderRadius: kRadius30,
                ),
                elevation: 0,
              ),
              child: Text(
                kContinueText,
                style: kDialogButtonTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap; // Make onTap nullable

  const _AreaItem({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap, // This now accepts nullable callbacks
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.location_city,
        color: selected ? kPrimaryColor : kBlack54,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: selected ? kPrimaryColor : kBlack,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: selected ? kPrimaryColor : kBlack54,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.radio_button_checked, color: kPrimaryColor)
          : const Icon(Icons.radio_button_off, color: kBlack54),
      onTap: onTap, // This will be null when _isLoading is true
      shape: RoundedRectangleBorder(
        borderRadius: kRadius10,
        side: selected
            ? const BorderSide(color: kPrimaryColor, width: 1.5)
            : BorderSide.none,
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFE3F0FB),
    );
  }
}
