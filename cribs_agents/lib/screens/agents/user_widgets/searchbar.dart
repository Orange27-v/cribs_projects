import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? icon;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: kGrey.withValues(alpha: 0.1),
        borderRadius: kRadius30,
        border: Border.all(
            color: kGrey.withValues(alpha: 0.1), width: 1), // ✅ FIXED
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.search, color: kPrimaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(color: kGrey, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
