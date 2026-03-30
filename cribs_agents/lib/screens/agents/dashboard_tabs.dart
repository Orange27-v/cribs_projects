import 'package:flutter/material.dart';
import '../../constants.dart';

class DashboardTabs extends StatefulWidget {
  final ValueChanged<int> onTabSelected;
  final int selectedIndex;

  const DashboardTabs(
      {super.key, required this.onTabSelected, this.selectedIndex = 0});

  @override
  State<DashboardTabs> createState() => _DashboardTabsState();
}

class _DashboardTabsState extends State<DashboardTabs> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: kLightBlue,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildTab(context, 'Active', 0)),
            Expanded(child: _buildTab(context, 'My Dashboard', 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String text, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        widget.onTabSelected(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: kWhite, // Light blue similar to image
                borderRadius: BorderRadius.circular(32),
              )
            : null,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: kPrimaryColor, // Stronger blue
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
