import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/bvn_service.dart';
import 'package:cribs_agents/screens/account/nin_screens/bvn_status_screen.dart';
import 'package:cribs_agents/utils/snackbar_helper.dart';
import 'package:cribs_agents/utils/error_handler.dart';
import 'package:flash/flash.dart';

class BvnVerificationScreen extends StatefulWidget {
  const BvnVerificationScreen({super.key});

  @override
  State<BvnVerificationScreen> createState() => _BvnVerificationScreenState();
}

class _BvnVerificationScreenState extends State<BvnVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bvnController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _gender;
  bool _isLoading = false;

  final BvnService _bvnService = BvnService();

  @override
  void initState() {
    super.initState();
    _checkExistingVerification();
  }

  /// Check if user already has a verification for BVN
  Future<void> _checkExistingVerification() async {
    try {
      final existingVerification =
          await _bvnService.checkExistingVerification('bvn');

      if (existingVerification['has_verification'] == true ||
          existingVerification['status'] == 'pending' ||
          existingVerification['status'] == 'verified') {
        // User already has a verification, navigate to status screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BvnStatusScreen(
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
    _bvnController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleBvnVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _bvnService.verifyBvn(
          bvn: _bvnController.text,
          firstname: _firstNameController.text,
          lastname: _lastNameController.text,
          dob: _dobController.text.isEmpty ? null : _dobController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          gender: _gender,
        );

        if (mounted) {
          SnackbarHelper.showSuccess(
              context, response['message'] ?? 'BVN verification initiated.',
              position: FlashPosition.bottom);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BvnStatusScreen(verificationId: response['verification_id']),
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
        title: Text('BVN VERIFICATION'),
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
                  'Enter your Bank Verification Number (BVN) and personal details to verify your account.',
                  style: TextStyle(fontSize: kFontSize16, color: kGrey),
                ),
                const SizedBox(height: kSizedBoxH24),
                CustomTextField(
                  controller: _bvnController,
                  labelText: 'BVN',
                  hintText: 'Enter your 11-digit BVN',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.account_balance,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your BVN';
                    }
                    if (value.length != 11) {
                      return 'BVN must be 11 digits';
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
                  text: 'Verify BVN',
                  onPressed: _isLoading ? null : _handleBvnVerification,
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
