import 'package:flutter/material.dart';
import '../../../constants.dart';

class ViewAgentProfileButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ViewAgentProfileButton({super.key, required this.onPressed});

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
            backgroundColor: kPrimaryColor,
            shape: const RoundedRectangleBorder(
              borderRadius: kRadius28,
            ),
            elevation: kElevation8,
            shadowColor: kPrimaryColorOpacity03,
          ),
          child: const Text(
            kViewAgentProfileText,
            style: TextStyle(
              color: kWhite,
              fontSize: kFontSize14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
