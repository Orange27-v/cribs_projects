import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';

class CustomPillSwitch extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onTabSelected;

  const CustomPillSwitch({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onTabSelected,
  }) : assert(labels.length == icons.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kLightBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: _buildTab(
              labels[index],
              index,
              icons[index],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? kPrimaryColor : kGrey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? kPrimaryColor : kGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
