import 'package:flutter/material.dart';
import '../../constants.dart';

class BackNavigator extends StatelessWidget {
  const BackNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Row(
        children: [
          Icon(Icons.arrow_back, color: kPrimaryColor),
          SizedBox(width: kSizedBoxW8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Back',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
                fontSize: kFontSize16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
