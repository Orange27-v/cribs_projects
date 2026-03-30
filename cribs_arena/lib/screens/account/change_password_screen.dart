import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

import 'package:cribs_arena/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/services/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _userService.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    // 1. Client-side validation
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmNewPasswordController.text.isEmpty) {
      SnackbarHelper.showError(context, 'All fields are required.',
          position: FlashPosition.bottom);
      return;
    }

    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      SnackbarHelper.showError(context, 'New passwords do not match.',
          position: FlashPosition.bottom);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      SnackbarHelper.showError(
          context, 'Password must be at least 6 characters long.',
          position: FlashPosition.bottom);
      return;
    }

    if (_newPasswordController.text == _currentPasswordController.text) {
      SnackbarHelper.showError(
          context, 'New password cannot be the same as the current password.',
          position: FlashPosition.bottom);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Update password in backend
      await _userService.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmNewPasswordController.text,
      );

      // 3. Show success and navigate back
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Password updated successfully!',
          position: FlashPosition.bottom);
      Navigator.of(context).pop();
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('wrong-password')) {
        errorMessage = 'Incorrect current password.';
      } else if (errorMessage.contains('weak-password')) {
        errorMessage = 'The new password is too weak.';
      }
      SnackbarHelper.showError(context, errorMessage,
          position: FlashPosition.bottom);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: kPaddingAll16,
        child: CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your password',
                style: GoogleFonts.roboto(
                  fontSize: kFontSize18,
                  fontWeight: FontWeight.bold,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: kSizedBoxH24),
              CustomPasswordField(
                controller: _currentPasswordController,
                labelText: 'Current Password',
                hintText: 'Enter your current password',
              ),
              const SizedBox(height: kSizedBoxH16),
              CustomPasswordField(
                controller: _newPasswordController,
                labelText: 'New Password',
                hintText: 'Enter your new password',
              ),
              const SizedBox(height: kSizedBoxH16),
              CustomPasswordField(
                controller: _confirmNewPasswordController,
                labelText: 'Confirm New Password',
                hintText: 'Confirm your new password',
              ),
              const SizedBox(height: kSizedBoxH24),
              _buildChangePasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return PrimaryButton(
      text: 'Change Password',
      isLoading: _isLoading,
      onPressed: _handleChangePassword,
    );
  }
}
