import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';

class ActionElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const ActionElevatedButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kLightBlue,
          padding: kPaddingV16,
          shape: const RoundedRectangleBorder(borderRadius: kRadius12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
