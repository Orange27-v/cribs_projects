import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants.dart';

export 'loading_overlay.dart';

class CircleImageContainer extends StatelessWidget {
  final String imagePath;
  final double size;
  const CircleImageContainer({
    super.key,
    required this.imagePath,
    this.size = kSizedBoxH100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCircleBg.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: kCircleBoxShadow,
      ),
      padding: kPaddingAll32,
      child: Image.asset(
        imagePath,
        height: size,
        width: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final Color? backgroundColor;
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: kSizedBoxH48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? kPrimaryColor,
          shape: const RoundedRectangleBorder(
            borderRadius: kRadius32,
          ),
          elevation: kSizedBoxH2,
          padding: kPaddingZero,
        ),
        child: isLoading
            ? const CustomLoadingIndicator(
                size: 24,
                strokeWidth: 2.5,
                color: kWhite,
                backgroundColor: Colors.transparent,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: kFontSize14,
                      fontWeight: FontWeight.w500,
                      color: kWhite,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: kSizedBoxW10),
                    icon!,
                  ],
                ],
              ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  const DialogButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? kLightPurple,
          foregroundColor: foregroundColor ?? kBlack,
          elevation: kElevation0,
          shape: const RoundedRectangleBorder(
            borderRadius: kRadius16,
          ),
          minimumSize: const Size.fromHeight(kSizedBoxH48),
        ),
        child: Text(text),
      ),
    );
  }
}

class OutlinedActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double borderRadius;
  final double? fontSize;
  const OutlinedActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.borderRadius = kRadiusDouble30,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.transparent,
        side: BorderSide(
            color: borderColor ?? kPrimaryColor, width: kStrokeWidth1_5),
        minimumSize: const Size.fromHeight(kSizedBoxH48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor ?? kPrimaryColor, size: kIconSize20),
            const SizedBox(width: kSizedBoxW8),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor ?? kPrimaryColor,
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class AgreementCheckbox extends StatelessWidget {
  final bool agreed;
  final VoidCallback onTap;
  final String termsText;
  final String privacyText;
  const AgreementCheckbox({
    super.key,
    required this.agreed,
    required this.onTap,
    this.termsText = 'Terms of Service',
    this.privacyText = 'Privacy Policy',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: kDuration200ms,
            width: kSize24,
            height: kSize24,
            decoration: BoxDecoration(
              color: agreed ? kPrimaryColor : Colors.transparent,
              border: Border.all(
                color: agreed ? kPrimaryColor : kGrey,
                width: kSizedBoxH2,
              ),
              borderRadius: kRadius4,
            ),
            child: agreed
                ? const Icon(Icons.check, color: kWhite, size: kIconSize16)
                : null,
          ),
        ),
        const SizedBox(width: kSizedBoxW12),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: kFontSize14,
                  color: kBlack87,
                  height: kSizedBoxH1_4, // Assuming kSizedBoxH1_4 is 1.4
                ),
                children: [
                  const TextSpan(text: 'I have read and agree to the '),
                  TextSpan(
                    text: termsText,
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: privacyText,
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- New Reusable Widgets for Authentication Screens ---
// In widgets.dart
class AuthTopBar extends StatelessWidget {
  final String buttonText;
  final VoidCallback onButtonPressed;
  final double
      horizontalPadding; // This is the parameter causing the error if not provided

  const AuthTopBar({
    super.key,
    required this.buttonText,
    required this.onButtonPressed,
    this.horizontalPadding = kSizedBoxH0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding, vertical: kPaddingV5.vertical),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/location_icon.png', height: kSizedBoxH40),
          TextButton(
            onPressed: onButtonPressed,
            style: TextButton.styleFrom(
              side: const BorderSide(
                  color: kPrimaryColor, width: kStrokeWidth1_5),
              shape: const RoundedRectangleBorder(
                borderRadius: kRadius30,
              ),
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              buttonText,
              style: kAuthTextButtonStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final String? title; // Added optional title parameter
  const AuthHeader({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/cribs_arena_logo_dark.png',
          height: kSizedBoxH40,
        ),
        const SizedBox(height: kSizedBoxH20),
        Image.asset(
          'assets/images/avatar_person.png',
          height: kSizedBoxH50,
          width: kSizedBoxW50,
        ),
        const SizedBox(height: kSizedBoxH30),
        if (title != null) // Conditionally display title
          Text(
            title!,
            style:
                kAuthHeaderTitleStyle, // Assuming this style is defined in constants.dart
          ),
        if (title != null)
          const SizedBox(height: kSizedBoxH20), // Spacing after title
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap; // Make this nullable
  final bool filled;
  final Color? fillColor;
  final String? initialValue;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled; // Add the enabled parameter

  // Add the private field to store the value

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap, // Now correctly nullable
    this.filled = false,
    this.fillColor,
    this.initialValue,
    this.validator,
    this.obscureText = false,
    this.maxLines,
    this.inputFormatters,
    this.enabled = true, // Default value
  }); // Assign the constructor argument to the private field

  // Define the getter for 'enabled'

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap, // Use the nullable onTap
      keyboardType: keyboardType,
      initialValue: initialValue,
      validator: validator,
      obscureText: obscureText,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled, // Use the enabled parameter here
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: const OutlineInputBorder(
          borderRadius: kRadius8,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: kRadius8,
          borderSide: BorderSide(color: kGrey300, width: kStrokeWidth1_5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: kRadius8,
          borderSide: BorderSide(color: kPrimaryColor, width: kStrokeWidth2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: kRadius8,
          borderSide: BorderSide(color: kRed, width: kStrokeWidth1_5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: kRadius8,
          borderSide: BorderSide(color: kRed, width: kStrokeWidth2),
        ),
        contentPadding: kPaddingAll16,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: fillColor,
      ),
    );
  }
}

class CustomPasswordField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  const CustomPasswordField({
    super.key,
    required this.labelText,
    required this.hintText,
    this.controller,
    this.validator,
    this.inputFormatters,
    this.enabled = true,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      labelText: widget.labelText,
      hintText: widget.hintText,
      controller: widget.controller,
      obscureText: _obscureText,
      maxLines: 1,
      keyboardType: TextInputType.visiblePassword,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: kGrey500,
          size: kIconSize24,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

class AuthDisclaimerText extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onLinkTap;

  const AuthDisclaimerText({
    super.key,
    required this.text,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPaddingAll24,
      child: GestureDetector(
        onTap: onLinkTap,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: text,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: kGrey500,
                ),
            children: [
              TextSpan(
                text: ' $linkText',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const OtpTextField(
      {super.key,
      required this.controller,
      required this.focusNode,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: kPaddingH10,
      width: kSizedBoxW50,
      height: kSizedBoxH50,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kSizedBoxW5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: kBlurRadius6,
            offset: kOffset02,
          ),
        ],
        border: Border.all(color: Colors.black12, width: kStrokeWidth1_5),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            fontSize: kFontSize22,
            fontWeight: FontWeight.w500,
            letterSpacing: kSizedBoxH1,
            color: kBlack87,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: kPaddingOnlyBottom2,
            filled: false,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class LabeledTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.maxLines,
    this.inputFormatters,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w500,
                color: kDarkBlue,
              ),
        ),
        const SizedBox(height: kSizedBoxH8),
        CustomTextField(
          hintText: hintText,
          labelText: '', // Label is handled by the Column's Text widget
          controller: controller,
          obscureText: obscureText,
          suffixIcon: suffixIcon,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          enabled: enabled,
        ),
      ],
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPaddingH8V4,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: kRadius12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/success.svg',
            height: kIconSize16,
            width: kIconSize16,
          ),
          const SizedBox(width: kSizedBoxW4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: kFontSize8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom loading indicator with primary color and white background
/// Use this instead of CircularProgressIndicator for consistent branding
class CustomLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const CustomLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? kWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? kPrimaryColor),
      ),
    );
  }
}

class AnimatedFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String? customText;
  final IconData? customIcon;
  final String? customSvgPath;

  const AnimatedFloatingActionButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.customText,
    this.customIcon,
    this.customSvgPath,
  });

  @override
  State<AnimatedFloatingActionButton> createState() =>
      _AnimatedFloatingActionButtonState();
}

class ViewAgentProfileButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  const ViewAgentProfileButton(
      {super.key, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPaddingH16V8,
      child: SizedBox(
        width: double.infinity,
        height: kSizedBoxH48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading
                ? kPrimaryColor.withValues(alpha: 0.8)
                : kPrimaryColor,
            shape: const RoundedRectangleBorder(
              borderRadius: kRadius28,
            ),
            elevation: kElevation8,
            shadowColor: kPrimaryColorOpacity03,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/profile_user.svg',
                height: kIconSize20,
                width: kIconSize20,
                colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
              ),
              const SizedBox(width: kSizedBoxW8),
              const Text(
                kViewAgentProfileText,
                style: TextStyle(
                  color: kWhite,
                  fontSize: kFontSize14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedFloatingActionButtonState
    extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: kDuration150ms,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: kScaleAnimationEnd095,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  Widget _buildIcon() {
    if (widget.isLoading) {
      return const CustomLoadingIndicator(
        size: 20,
        strokeWidth: 2,
        color: kWhite,
        backgroundColor: Colors.transparent,
      );
    }

    if (widget.customSvgPath != null) {
      return SvgPicture.asset(
        widget.customSvgPath!,
        height: kSizedBoxH20,
        width: kSizedBoxW20,
        colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
      );
    }

    if (widget.customIcon != null) {
      return Icon(
        widget.customIcon,
        color: kWhite,
        size: kIconSize20,
      );
    }

    // Default SVG icon
    return SvgPicture.asset(
      kMapSearchIconPath,
      height: kSizedBoxH20,
      width: kSizedBoxW20,
      colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
    );
  }

  String _getButtonText() {
    if (widget.isLoading) {
      return kSearchingText;
    }
    return widget.customText ?? kFindAgentsNearMeText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPaddingH16V8,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: widget.isLoading ? null : widget.onPressed,
              child: AnimatedContainer(
                duration: kDuration200ms,
                width: double.infinity,
                height: kSizedBoxH48,
                decoration: BoxDecoration(
                  color: widget.isLoading
                      ? kPrimaryColor.withValues(alpha: 0.8)
                      : kPrimaryColor,
                  borderRadius: kRadius28,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(
                          alpha: _isPressed ? 0.2 : 0.3),
                      blurRadius: _isPressed ? kBlurRadius4 : kBlurRadius8,
                      offset: _isPressed ? kOffset02 : kOffset04,
                      spreadRadius: _isPressed ? 0 : kSizedBoxH1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: kRadius28,
                    onTap: widget.isLoading ? null : widget.onPressed,
                    splashColor: kWhiteOpacity01,
                    highlightColor: kWhiteOpacity005,
                    child: Container(
                      padding: kPaddingH16V8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildIcon(),
                          const SizedBox(width: kSizedBoxW12),
                          Flexible(
                            child: Text(
                              _getButtonText(),
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: kFontSize14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A widget to display a price formatted with currency symbol and decimal digits.
///
/// Requires the `intl: ^0.18.0` package to be added to pubspec.yaml.
class FormattedPrice extends StatelessWidget {
  final double price;
  final TextStyle? style;
  final String symbol;

  const FormattedPrice({
    super.key,
    required this.price,
    this.style,
    this.symbol = nairaSymbol, // Default to Naira symbol based on existing code
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    final formattedPrice = formatCurrency.format(price);

    return Text(
      formattedPrice,
      style: style,
    );
  }
}

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const PrimaryAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = kElevation05,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? kWhite;
    final effectiveForegroundColor = foregroundColor ?? kPrimaryColor;

    return AppBar(
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation,
      scrolledUnderElevation:
          elevation > 0 ? elevation + kSizedBoxH2 : kSizedBoxH0,
      centerTitle: centerTitle,
      title: title != null
          ? DefaultTextStyle(
              style: GoogleFonts.roboto(
                color: effectiveForegroundColor,
                fontWeight: FontWeight.bold,
                fontSize: kFontSize18,
              ),
              child: title!,
            )
          : null,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(color: effectiveForegroundColor),
      systemOverlayStyle: systemOverlayStyle ??
          SystemUiOverlayStyle(
            statusBarColor: effectiveBackgroundColor,
            statusBarIconBrightness: Brightness.dark, // For light backgrounds
            statusBarBrightness: Brightness.light, // For iOS
          ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    this.message = 'No conversations found.',
    this.icon = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kCircleBg.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              boxShadow: kCircleBoxShadow,
            ),
            padding: kPaddingAll32,
            child: Icon(
              icon,
              size: kSize60,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: kSizedBoxH20),
          Text(
            message,
            style: GoogleFonts.roboto(
              fontSize: kFontSize12,
              color: kGrey,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Helper function to convert exceptions to user-friendly messages
String getErrorMessage(dynamic error) {
  if (error == null) return 'Something went wrong. Please try again.';

  String errorString = error.toString();

  // Handle NetworkException
  if (errorString.contains('NetworkException')) {
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Connection timed out. Please check your internet and try again.';
    } else if (errorString.contains('noConnection') ||
        errorString.contains('No internet') ||
        errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network settings.';
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return 'Session expired. Please log in again.';
    } else if (errorString.contains('notFound') ||
        errorString.contains('404')) {
      return 'The requested information could not be found.';
    } else if (errorString.contains('serverError') ||
        errorString.contains('500') ||
        errorString.contains('530') ||
        errorString.contains('Internal Server Error')) {
      return 'Server error. Please try again later.';
    } else if (errorString.contains('badRequest') ||
        errorString.contains('400')) {
      return 'Invalid request. Please try again.';
    }
  }

  // Handle other common exceptions
  if (errorString.contains('TimeoutException') ||
      errorString.contains('timeout')) {
    return 'Connection timed out. Please check your internet and try again.';
  }

  if (errorString.contains('SocketException') ||
      errorString.contains('Failed host lookup') ||
      errorString.contains('Network is unreachable')) {
    return 'No internet connection. Please check your network settings.';
  }

  if (errorString.contains('FormatException') ||
      errorString.contains('Invalid JSON')) {
    return 'Unable to process server response. Please try again.';
  }

  // Clean up generic exception messages
  String cleanMessage = errorString
      .replaceFirst('Exception: ', '')
      .replaceFirst('NetworkException: ', '')
      .replaceFirst(RegExp(r'\(type:.*\)'), '')
      // Remove error codes like "530 - error code: 1033"
      .replaceAll(RegExp(r'\d{3}\s*-\s*error code:\s*\d+'), '')
      // Remove standalone HTTP status codes
      .replaceAll(RegExp(r'\b[45]\d{2}\b'), '')
      // Remove "Failed to load X:" prefix
      .replaceFirst(RegExp(r'^Failed to load [^:]+:\s*'), '')
      .trim();

  // If the cleaned message is too technical, empty, or still contains error codes, return a generic message
  if (cleanMessage.isEmpty ||
      cleanMessage.length > 100 ||
      cleanMessage.contains('Instance of') ||
      cleanMessage.contains('Null check operator') ||
      cleanMessage.contains('error code:') ||
      RegExp(r'\d{3,}').hasMatch(cleanMessage)) {
    return 'Something went wrong. Please try again.';
  }

  return cleanMessage;
}

/// A widget to display network errors with pull-to-refresh functionality
class NetworkErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRefresh;
  final String? title;
  final IconData? icon;

  const NetworkErrorWidget({
    super.key,
    this.errorMessage,
    required this.onRefresh,
    this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = errorMessage != null
        ? getErrorMessage(errorMessage)
        : 'Something went wrong. Please try again.';

    return Center(
      child: Padding(
        padding: kPaddingAll24,
        child: CardContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kCircleBg.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: kCircleBoxShadow,
                ),
                padding: kPaddingAll32,
                child: Icon(
                  icon ?? Icons.wifi_off_rounded,
                  size: kSize60,
                  color: kGrey500,
                ),
              ),
              const SizedBox(height: kSizedBoxH24),
              if (title != null) ...[
                Text(
                  title!,
                  style: GoogleFonts.roboto(
                    fontSize: kFontSize18,
                    fontWeight: FontWeight.bold,
                    color: kDarkTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kSizedBoxH12),
              ],
              Text(
                displayMessage,
                style: GoogleFonts.roboto(
                  fontSize: kFontSize14,
                  color: kGrey600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kSizedBoxH32),
              OutlinedActionButton(
                text: 'Pull down to refresh',
                icon: Icons.refresh,
                onPressed: onRefresh,
                borderColor: kPrimaryColor,
                textColor: kPrimaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  final String svgPath;
  final String title;
  final String? subtitle; // Make subtitle optional
  final VoidCallback? onTap;
  final Widget? trailing;

  const OptionTile({
    super.key,
    required this.svgPath,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: subtitle != null
            ? kSizedBoxH80
            : kSizedBoxH48, // Adjust height based on subtitle
        padding: kPaddingH16,
        decoration: BoxDecoration(
          color: onTap != null ? kWhite : kGrey100,
          borderRadius: kRadius12,
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: kOffset02,
                    blurRadius: kBlurRadius6,
                    spreadRadius: kSizedBoxH0,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            SvgPicture.asset(svgPath,
                colorFilter: ColorFilter.mode(
                    onTap != null ? kPrimaryColor : kGrey, BlendMode.srcIn),
                width: kSize24,
                height: kSize24),
            const SizedBox(width: kSizedBoxW12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      fontSize: kFontSize14,
                      color: onTap != null ? kBlack : kGrey,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.roboto(
                        fontSize: kFontSize12,
                        color: kGrey,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                SvgPicture.asset('assets/icons/arrow_forward_ios.svg',
                    colorFilter: ColorFilter.mode(
                        onTap != null ? kGrey : kGrey.withValues(alpha: 0.5),
                        BlendMode.srcIn),
                    width: kIconSize16,
                    height: kIconSize16),
          ],
        ),
      ),
    );
  }
}

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const CardContainer({
    super.key,
    required this.child,
    this.padding = kPaddingAll20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kRadius8, // Using 12 to match OptionTile
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: kOffset02,
            blurRadius: kSizedBoxH2,
            spreadRadius: kSizedBoxH0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class CustomAlertDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: kRadius16,
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }
}

class CustomDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const CustomDatePicker({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText,
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: kPrimaryColor, // header background color
                  onPrimary: kWhite, // header text color
                  onSurface: kBlack, // body text color
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryColor, // button text color
                  ),
                ),
                dialogTheme: DialogThemeData(backgroundColor: kWhite),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          controller.text = pickedDate.toIso8601String().split('T')[0];
        }
      },
    );
  }
}

/// Custom Refresh Indicator Widget
/// A reusable pull-to-refresh widget with a modern, premium design
/// that matches the app's design system.
class CustomRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double displacement;

  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 3.0,
    this.displacement = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? kPrimaryColor,
      backgroundColor: backgroundColor ?? kWhite,
      strokeWidth: strokeWidth,
      displacement: displacement,
      // Modern elevation and styling
      edgeOffset: 0.0,
      child: child,
    );
  }
}

/// Custom Loading Spinner Widget
/// A reusable loading spinner with a modern, branded design
/// that matches the app's design system.
/// Features: kPrimaryColor spinner with kWhite background and shadow
class CustomLoadingSpinner extends StatelessWidget {
  final Color? color;
  final double? size;
  final double? strokeWidth;
  final Color? backgroundColor;

  const CustomLoadingSpinner({
    super.key,
    this.color,
    this.size,
    this.strokeWidth,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final double containerSize = size ?? 40.0;
    return Container(
      width: containerSize,
      height: containerSize,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? kWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircularProgressIndicator(
        color: color ?? kPrimaryColor,
        strokeWidth: strokeWidth ?? 3.0,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

// --- Custom Bottom Sheet Widget ---
/// A reusable bottom sheet widget with consistent styling
/// Follows the design pattern from signup_screen.dart
class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final double initialChildSize;
  final double maxChildSize;
  final double minChildSize;
  final bool expand;
  final bool showDragHandle;

  const CustomBottomSheet({
    super.key,
    required this.child,
    this.initialChildSize = 0.6,
    this.maxChildSize = 0.9,
    this.minChildSize = 0.3,
    this.expand = false,
    this.showDragHandle = true,
  });

  /// Helper method to show the bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double initialChildSize = 0.6,
    double maxChildSize = 0.9,
    double minChildSize = 0.3,
    bool expand = false,
    bool showDragHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        minChildSize: minChildSize,
        expand: expand,
        builder: (context, scrollController) {
          return CustomBottomSheet(
            initialChildSize: initialChildSize,
            maxChildSize: maxChildSize,
            minChildSize: minChildSize,
            expand: expand,
            showDragHandle: showDragHandle,
            child: _BottomSheetContent(
              scrollController: scrollController,
              showDragHandle: showDragHandle,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _BottomSheetContent extends StatelessWidget {
  final ScrollController scrollController;
  final bool showDragHandle;
  final Widget child;

  const _BottomSheetContent({
    required this.scrollController,
    required this.showDragHandle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: kGrey.shade300,
                  borderRadius: kRadius10,
                ),
              ),
            ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSizedBoxW16),
              child: ListView(
                controller: scrollController,
                shrinkWrap: true,
                children: [child],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NEW REUSABLE WIDGETS FOR UI REFACTORING
// ============================================================================

/// 1. SectionCard - Reusable card with shadow and padding
/// Used for displaying content sections with consistent styling
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? kPaddingAll12,
      decoration: BoxDecoration(
        color: backgroundColor ?? kWhite,
        borderRadius: borderRadius ?? kRadius12,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: kBlack.withValues(alpha: 0.08),
                blurRadius: kBlurRadius8,
                offset: kOffset02,
              ),
            ],
      ),
      child: child,
    );
  }
}

/// 2. ListItemCard - Standard list item container
/// Used for list items with consistent spacing and styling
class ListItemCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const ListItemCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? kPaddingAll16,
      decoration: BoxDecoration(
        color: backgroundColor ?? kWhite,
        borderRadius: kRadius12,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: kRadius12,
        child: container,
      );
    }

    return container;
  }
}

/// 3. CircularIconButton - Circular button with icon
/// Used for floating action buttons and icon buttons
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? iconSize;
  final double? elevation;
  final double? padding;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.iconSize,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? kWhite,
      shape: const CircleBorder(),
      elevation: elevation ?? 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(padding ?? 5),
          child: Icon(
            icon,
            color: iconColor ?? kPrimaryColor,
            size: iconSize ?? kIconSize18,
          ),
        ),
      ),
    );
  }
}

/// 4. SectionHeader - Section title with consistent styling
/// Used for section headers throughout the app
class SectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.padding,
    this.textStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? kPaddingOnlyLeft16Bottom8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: textStyle ??
                GoogleFonts.roboto(
                  fontSize: kFontSize12,
                  fontWeight: FontWeight.w500,
                  color: kGrey600,
                  letterSpacing: 1.2,
                ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 5. ProfileAvatarWithBadge - Avatar with edit/camera badge
/// Used for profile pictures with edit functionality
class ProfileAvatarWithBadge extends StatelessWidget {
  final ImageProvider imageProvider;
  final double radius;
  final VoidCallback? onBadgeTap;
  final IconData? badgeIcon;
  final Color? badgeColor;

  const ProfileAvatarWithBadge({
    super.key,
    required this.imageProvider,
    this.radius = kRadius35,
    this.onBadgeTap,
    this.badgeIcon,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
          backgroundColor: kGrey100,
        ),
        if (onBadgeTap != null)
          Positioned(
            bottom: kBottomNeg5,
            right: kRightNeg5,
            child: GestureDetector(
              onTap: onBadgeTap,
              child: Container(
                padding: kPaddingAll4,
                decoration: BoxDecoration(
                  color: badgeColor ?? kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badgeIcon ?? Icons.camera_alt,
                  color: kWhite,
                  size: kIconSize16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 6. AvatarWithStatus - Avatar with online/offline indicator
/// Used for user/agent avatars with status
class AvatarWithStatus extends StatelessWidget {
  final ImageProvider imageProvider;
  final bool isOnline;
  final double radius;
  final double statusSize;

  const AvatarWithStatus({
    super.key,
    required this.imageProvider,
    required this.isOnline,
    this.radius = 20,
    this.statusSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
          backgroundColor: kGrey100,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: statusSize,
            height: statusSize,
            decoration: BoxDecoration(
              color: isOnline ? kGreen : kGrey,
              shape: BoxShape.circle,
              border: Border.all(color: kWhite, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// 7. CustomDivider - Styled divider with spacing
/// Used for separating content sections
class CustomDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const CustomDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness ?? 1,
      color: color ?? kGrey300,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
    );
  }
}

/// 8. StatusChip - Colored chip for status/tags
/// Used for displaying status badges and tags
class StatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const StatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? kPaddingH12V6,
      decoration: BoxDecoration(
        color: backgroundColor ?? kPrimaryColorOpacity01,
        borderRadius: borderRadius ?? kRadius16,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: kIconSize12,
              color: textColor ?? kPrimaryColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: kFontSize10,
              fontWeight: FontWeight.w500,
              color: textColor ?? kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 9. SettingsListTile - Consistent settings list item
/// Used for settings and profile menu items
class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: kPaddingAll8,
        decoration: BoxDecoration(
          color: iconBackgroundColor ?? kPrimaryColorOpacity01,
          borderRadius: kRadius8,
        ),
        child: Icon(
          icon,
          color: iconColor ?? kPrimaryColor,
          size: kIconSize20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: kFontSize14,
          fontWeight: FontWeight.w500,
          color: kBlack87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.roboto(
                fontSize: kFontSize12,
                color: kBlack54,
              ),
            )
          : null,
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            color: kGrey400,
          ),
      onTap: onTap,
    );
  }
}

/// 10. InfoRow - Icon + text row pattern
/// Used for displaying information with icons
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;
  final double? iconSize;
  final double? spacing;
  final TextStyle? textStyle;
  final MainAxisAlignment? mainAxisAlignment;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
    this.iconSize,
    this.spacing,
    this.textStyle,
    this.mainAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize ?? kIconSize16,
          color: iconColor ?? kGrey,
        ),
        SizedBox(width: spacing ?? 5),
        Flexible(
          child: Text(
            text,
            style: textStyle ??
                GoogleFonts.roboto(
                  fontSize: kFontSize12,
                  color: textColor ?? kBlack54,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Resolves an image URL based on the provided path and configuration.
/// Handles both property images and general profile pictures.
String getResolvedImageUrl(String? path, {bool isProperty = false}) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;

  // Clean the base URL to ensure no trailing slash
  final String baseUrl = kMainBaseUrl.endsWith('/')
      ? kMainBaseUrl.substring(0, kMainBaseUrl.length - 1)
      : kMainBaseUrl;

  String finalPath = path;

  // Property-specific path prepending
  if (isProperty) {
    if (!finalPath.contains('/') && !finalPath.startsWith('property_images/')) {
      finalPath = 'property_images/$finalPath';
    }
  }

  // Ensure 'storage/' is present in the path if it's a relative path
  if (!finalPath.startsWith('storage/') && !finalPath.startsWith('/storage/')) {
    finalPath =
        'storage/${finalPath.startsWith('/') ? finalPath.substring(1) : finalPath}';
  }

  // Join the base URL with the final path
  if (finalPath.startsWith('/')) {
    return '$baseUrl$finalPath';
  } else {
    return '$baseUrl/$finalPath';
  }
}

/// Returns an [ImageProvider] (either NetworkImage or AssetImage) for a given path.
/// Automatically handles default placeholders and URL resolution.
ImageProvider getResolvedImageProvider(String? path,
    {bool isProperty = false}) {
  if (path == null ||
      path.isEmpty ||
      path == 'default_profile.jpg' ||
      path.contains('default_profile')) {
    return const AssetImage('assets/images/default_profile.jpg');
  }

  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }

  return NetworkImage(getResolvedImageUrl(path, isProperty: isProperty));
}
