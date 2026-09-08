import 'package:flutter/material.dart';
import 'package:hooko_v20/utils/responsive_size.dart';
import 'package:hooko_v20/components/nav_item.dart';

/// A reusable bottom navigation bar with three tabs.
/// Optimized with RepaintBoundary for smooth performance.
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.horizontalPadding(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavItem(
              iconPath: 'assets/icons/icon_analysis.svg',
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            NavItem(
              iconPath: 'assets/icons/icon_history.svg',
              label: 'History',
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            NavItem(
              iconPath: 'assets/icons/icon_profile.svg',
              label: 'Profile',
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}
