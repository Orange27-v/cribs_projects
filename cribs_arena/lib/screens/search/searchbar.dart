import 'package:flutter/material.dart';
import 'package:cribs_arena/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/screens/search/search_screen.dart';
import 'package:cribs_arena/screens/search/filter_bottom_sheet.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? icon;
  final bool enableNavigation;
  final bool showFilterIcon;
  final VoidCallback? onFilterTap;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.icon,
    this.enableNavigation = true,
    this.showFilterIcon = false,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    // If no controller is provided and navigation is enabled, make it tappable
    final shouldNavigate = controller == null && enableNavigation;

    return GestureDetector(
      onTap: shouldNavigate
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: kGrey.withValues(alpha: 0.1),
          borderRadius: kRadius30,
          border: Border.all(color: kGrey.withValues(alpha: 0.1), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.search,
              color: kPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: shouldNavigate
                  ? Text(
                      hintText,
                      style: GoogleFonts.roboto(
                        color: kGrey,
                        fontSize: 14,
                      ),
                    )
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: GoogleFonts.roboto(
                          color: kGrey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
            ),
            // Filter Icon
            if (showFilterIcon)
              GestureDetector(
                onTap: onFilterTap ??
                    () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const FilterBottomSheet(),
                      );
                    },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.tune,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
