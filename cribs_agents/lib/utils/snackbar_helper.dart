import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';

/// Helper class for displaying consistent snackbar notifications throughout the app
/// Uses the Flash package for better UX and customization
class SnackbarHelper {
  /// Shows a success snackbar with green styling
  ///
  /// [context] - BuildContext required for showing the snackbar
  /// [message] - The success message to display
  /// [action] - Optional action button (currently not used with Flash)
  /// [position] - Position of the snackbar (default: bottom)
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    FlashPosition position = FlashPosition.bottom,
  }) {
    context.showSuccessBar(
      content: Text(
        message,
        style: GoogleFonts.roboto(
          fontSize: kFontSize14,
          fontWeight: FontWeight.w500,
        ),
      ),
      position: position,
    );
  }

  /// Shows an error snackbar with red styling
  ///
  /// [context] - BuildContext required for showing the snackbar
  /// [message] - The error message to display
  /// [action] - Optional action button (currently not used with Flash)
  /// [position] - Position of the snackbar (default: bottom)
  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    FlashPosition position = FlashPosition.bottom,
  }) {
    context.showErrorBar(
      content: Text(
        message,
        style: GoogleFonts.roboto(
          fontSize: kFontSize14,
          fontWeight: FontWeight.w500,
        ),
      ),
      position: position,
    );
  }

  /// Shows an info snackbar with blue styling
  ///
  /// [context] - BuildContext required for showing the snackbar
  /// [message] - The info message to display
  /// [action] - Optional action button (currently not used with Flash)
  /// [position] - Position of the snackbar (default: bottom)
  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    FlashPosition position = FlashPosition.bottom,
  }) {
    context.showInfoBar(
      content: Text(
        message,
        style: GoogleFonts.roboto(
          fontSize: kFontSize14,
          fontWeight: FontWeight.w500,
        ),
      ),
      position: position,
    );
  }

  /// Shows a warning snackbar with orange styling
  ///
  /// [context] - BuildContext required for showing the snackbar
  /// [message] - The warning message to display
  /// [position] - Position of the snackbar (default: bottom)
  static void showWarning(
    BuildContext context,
    String message, {
    FlashPosition position = FlashPosition.bottom,
  }) {
    context.showFlash(
      duration: const Duration(seconds: 3),
      builder: (context, controller) {
        return Flash(
          controller: controller,
          position: position,
          child: FlashBar(
            controller: controller,
            icon: Icon(
              Icons.warning,
              color: kOrange,
              size: kIconSize24,
            ),
            content: Text(
              message,
              style: GoogleFonts.roboto(
                fontSize: kFontSize14,
                fontWeight: FontWeight.w500,
                color: kOrange600,
              ),
            ),
            primaryAction: IconButton(
              onPressed: () => controller.dismiss(),
              icon: const Icon(Icons.close, color: kGrey),
            ),
          ),
        );
      },
    );
  }
}
