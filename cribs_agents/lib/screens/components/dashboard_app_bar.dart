import 'package:flutter/material.dart';
import '../../constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double? leadingWidth;
  final Color backgroundColor;
  final double elevation;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.leadingWidth,
    this.backgroundColor = kWhite,
    this.elevation = 0,
    this.automaticallyImplyLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      leading: leading,
      title: title,
      actions: actions,
      leadingWidth: leadingWidth,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
