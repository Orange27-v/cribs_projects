import 'package:flutter/material.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/services/nin_service.dart'; // Import NinService
import 'package:cribs_arena/screens/account/nin_screens/nin_status_screen.dart'; // Import NinStatusScreen
import 'package:cribs_arena/utils/snackbar_helper.dart'; // For SnackbarHelper
import 'package:cribs_arena/utils/error_handler.dart';
import 'package:flash/flash.dart'; // For FlashPosition

class NinVerificationDetailsScreen extends StatefulWidget {
  const NinVerificationDetailsScreen({super.key});

  @override
  State<NinVerificationDetailsScreen> createState() =>
      _NinVerificationDetailsScreenState();
}

class _NinVerificationDetailsScreenState
    extends State<NinVerificationDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ninController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _gender;
  bool _isLoading = false; // Add loading state

  final NinService _ninService = NinService(); // Instantiate NinService

  @override
  void initState() {
    super.initState();
    _checkExistingVerification();
  }

  /// Check if user already has a verification for NIN
  Future<void> _checkExistingVerification() async {
    try {
      final existingVerification =
          await _ninService.checkExistingVerification('nin');

      if (existingVerification['has_verification'] == true ||
          existingVerification['status'] == 'pending' ||
          existingVerification['status'] == 'verified') {
        // User already has a verification, navigate to status screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NinStatusScreen(
                verificationId: existingVerification['verification_id'],
              ),
            ),
          );
        }
      }
    } catch (e) {
      // If check fails, continue to show form (user can still submit)
    }
  }

  @override
  void dispose() {
    _ninController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleNinVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _ninService.verifyNin(
          nin: _ninController.text,
          firstname: _firstNameController.text,
          lastname: _lastNameController.text,
          dob: _dobController.text.isEmpty ? null : _dobController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          gender: _gender,
        );

        if (mounted) {
          SnackbarHelper.showSuccess(
              context, response['message'] ?? 'NIN verification initiated.',
              position: FlashPosition.bottom);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NinStatusScreen(verificationId: response['verification_id']),
            ),
          );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('NIN VERIFICATION'),
      ),
      body: SingleChildScrollView(
        padding: kPaddingAll16,
        child: CardContainer(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your National Identification Number (NIN) and personal details to verify your account.',
                  style: TextStyle(fontSize: kFontSize16, color: kGrey),
                ),
                const SizedBox(height: kSizedBoxH24),
                CustomTextField(
                  controller: _ninController,
                  labelText: 'NIN',
                  hintText: 'Enter your 11-digit NIN',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.credit_card,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your NIN';
                    }
                    if (value.length != 11) {
                      return 'NIN must be 11 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: kSizedBoxH16),
                CustomTextField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your first name' : null,
                ),
                const SizedBox(height: kSizedBoxH16),
                CustomTextField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your last name' : null,
                ),
                const SizedBox(height: kSizedBoxH16),
                CustomDatePicker(
                  controller: _dobController,
                  hintText: 'Date of Birth (YYYY-MM-DD)',
                ),
                const SizedBox(height: kSizedBoxH16),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number (Optional)',
                  hintText: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: kSizedBoxH16),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email Address (Optional)',
                  hintText: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: kSizedBoxH16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  hint: const Text('Select Gender'),
                  items: ['Male', 'Female'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _gender = newValue;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Gender (Optional)',
                    border: OutlineInputBorder(borderRadius: kRadius8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: kRadius8,
                      borderSide:
                          BorderSide(color: kGrey300, width: kStrokeWidth1_5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: kRadius8,
                      borderSide: BorderSide(
                          color: kPrimaryColor, width: kStrokeWidth2),
                    ),
                    contentPadding: kPaddingAll16,
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                ),
                const SizedBox(height: kSizedBoxH32),
                PrimaryButton(
                  text: 'Verify NIN',
                  onPressed: _isLoading ? null : _handleNinVerification,
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
