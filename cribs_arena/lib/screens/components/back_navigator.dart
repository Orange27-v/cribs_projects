import 'package:flutter/material.dart';
import '../../constants.dart';

class BackNavigator extends StatelessWidget {
  final bool showText;
  const BackNavigator({super.key, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: [
          const Icon(Icons.arrow_back, color: kPrimaryColor),
          if (showText) const SizedBox(width: 8),
          if (showText)
            const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Back',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
