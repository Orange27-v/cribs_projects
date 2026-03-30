import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/vnin_service.dart'; // Import VninService
import 'package:cribs_agents/screens/account/nin_screens/vnin_status_screen.dart'; // Import VninStatusScreen
import 'package:cribs_agents/utils/snackbar_helper.dart'; // For SnackbarHelper
import 'package:cribs_agents/utils/error_handler.dart';
import 'package:flash/flash.dart'; // For FlashPosition

class VninVerificationScreen extends StatefulWidget {
  const VninVerificationScreen({super.key});

  @override
  State<VninVerificationScreen> createState() => _VninVerificationScreenState();
}

class _VninVerificationScreenState extends State<VninVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vninController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;
  bool _isLoading = false; // Add loading state

  final VninService _vninService = VninService(); // Instantiate VninService

  @override
  void initState() {
    super.initState();
    _checkExistingVerification();
  }

  /// Check if user already has a verification for vNIN
  Future<void> _checkExistingVerification() async {
    try {
      final existingVerification =
          await _vninService.checkExistingVerification('vnin');

      if (existingVerification['has_verification'] == true) {
        // User already has a verification, navigate to status screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VninStatusScreen(
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
    _vninController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _handleVninVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _vninService.verifyVnin(
          vnin: _vninController.text,
          firstname: _firstNameController.text,
          lastname: _lastNameController.text,
          dob: _dobController.text.isEmpty ? null : _dobController.text,
          gender: _gender,
        );

        if (mounted) {
          SnackbarHelper.showSuccess(
              context, response['message'] ?? 'vNIN verification initiated.',
              position: FlashPosition.bottom);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VninStatusScreen(verificationId: response['verification_id']),
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
        title: Text('VNIN VERIFICATION'),
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
                  'Enter your Virtual NIN and personal details to verify your account.',
                  style: TextStyle(fontSize: kFontSize16, color: kGrey),
                ),
                const SizedBox(height: kSizedBoxH24),
                CustomTextField(
                  controller: _vninController,
                  labelText: 'Virtual NIN',
                  hintText: 'Enter your vNIN',
                  prefixIcon: Icons.credit_card,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your vNIN';
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
                  text: 'Verify vNIN',
                  onPressed: _isLoading ? null : _handleVninVerification,
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
