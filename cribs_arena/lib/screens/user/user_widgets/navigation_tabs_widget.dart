// lib/screen/user/user_widgets/navigation_tabs_widget.dart
import 'package:flutter/material.dart';
import '../../../constants.dart'; // Adjust path as necessary

class NavigationTabsWidget extends StatelessWidget {
  final int currentTabIndex;
  final GlobalKey tabBarKey;
  final double indicatorLeft;
  final double indicatorWidth;
  final ValueChanged<int> onTabChanged;

  const NavigationTabsWidget({
    super.key,
    required this.currentTabIndex,
    required this.tabBarKey,
    required this.indicatorLeft,
    required this.indicatorWidth,
    required this.onTabChanged,
  });

  // Helper method for individual tabs (now part of this widget)
  Widget _buildTab(String title, int index) {
    final isSelected = currentTabIndex == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Container(
        alignment: Alignment.center,
        padding: kPaddingH4V8,
        decoration: BoxDecoration(
          color: isSelected ? kGrey100Opacity06 : Colors.transparent,
          borderRadius: kRadius8,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: kFontSize16,
            fontWeight: FontWeight.w500,
            color: isSelected ? kPrimaryColor : kBlack,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPaddingH16,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          SizedBox(
            height: kSizedBoxH40,
            child: Row(
              key: tabBarKey,
              children: [
                Expanded(child: _buildTab(kSearchText, 0)),
                Expanded(child: _buildTab(kMyFeedText, 1)),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: kDuration300ms,
            curve: Curves.easeOutCubic,
            left: indicatorLeft,
            width: indicatorWidth,
            height: kSizedBoxH3,
            bottom: kSizedBoxH0,
            child: Container(
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: kRadius2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
