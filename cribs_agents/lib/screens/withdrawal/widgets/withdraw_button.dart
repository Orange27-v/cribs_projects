import 'package:flutter/material.dart';

import '../../../../widgets/widgets.dart';

class WithdrawButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isWithdrawing;

  const WithdrawButton({
    super.key,
    required this.onPressed,
    required this.isWithdrawing,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: 'Withdraw Funds',
      onPressed: onPressed,
      isLoading: isWithdrawing,
    );
  }
}
