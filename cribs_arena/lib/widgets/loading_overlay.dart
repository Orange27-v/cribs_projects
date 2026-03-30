import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'widgets.dart';

/// A reusable full-screen loading overlay widget
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     YourContent(),
///     if (isLoading) LoadingOverlay(message: 'Loading...'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  /// Optional message to display below the spinner
  final String? message;

  /// Color of the overlay background (default: semi-transparent black)
  final Color? backgroundColor;

  /// Color of the progress indicator (default: white)
  final Color? indicatorColor;

  /// Whether the overlay can be dismissed by tapping (default: false)
  final bool dismissible;

  /// Size of the progress indicator (default: null - uses default size)
  final double? size;

  const LoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
    this.dismissible = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          dismissible: dismissible,
          color: backgroundColor ?? Colors.black54,
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomLoadingSpinner(
                color: indicatorColor ?? Colors.white,
                size: size ?? 50.0,
                strokeWidth: size != null ? size! / 12 : 4.0,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A simpler loading overlay without the modal barrier
/// Useful for inline loading states
class SimpleLoadingOverlay extends StatelessWidget {
  /// Optional message to display below the spinner
  final String? message;

  /// Color of the overlay background (default: semi-transparent black)
  final Color? backgroundColor;

  /// Color of the progress indicator (default: primary color)
  final Color? indicatorColor;

  const SimpleLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black26,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomLoadingSpinner(
              color: indicatorColor ?? kPrimaryColor,
              size: 45.0,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A centered loading indicator without overlay
/// Useful for initial page loads
class CenteredLoadingIndicator extends StatelessWidget {
  /// Color of the progress indicator (default: primary color)
  final Color? color;

  /// Optional message to display below the spinner
  final String? message;

  const CenteredLoadingIndicator({
    super.key,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomLoadingSpinner(
            color: color ?? kPrimaryColor,
            size: 45.0,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.roboto(
                color: kGrey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
