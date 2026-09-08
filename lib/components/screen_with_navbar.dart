import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/components/bottom_nav_bar.dart';
import 'package:hooko_v20/nav.dart';

/// A reusable screen wrapper that includes the bottom navigation bar.
/// Use this for any page that needs the standard navbar layout.
class ScreenWithNavbar extends StatefulWidget {
  final Widget child;
  final int initialNavIndex;
  final ValueChanged<int>? onNavTap;
  final bool safeAreaBottom;

  const ScreenWithNavbar({
    super.key,
    required this.child,
    this.initialNavIndex = 0,
    this.onNavTap,
    this.safeAreaBottom = false,
  });

  @override
  State<ScreenWithNavbar> createState() => _ScreenWithNavbarState();
}

class _ScreenWithNavbarState extends State<ScreenWithNavbar> {
  late int _selectedNavIndex;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
  }

  void _handleNavTap(int index) {
    if (index == _selectedNavIndex) return;
    
    setState(() => _selectedNavIndex = index);
    widget.onNavTap?.call(index);
    
    // Navigate to the corresponding screen
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.history);
        break;
      case 2:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive bottom spacing: safe area + 6dp for consistent look across all iPhones
    final bottomPadding = MediaQuery.of(context).padding.bottom + 6;
    
    return Column(
      children: [
        Expanded(child: widget.child),
        BottomNavBar(
          selectedIndex: _selectedNavIndex,
          onTap: _handleNavTap,
        ),
        SizedBox(height: bottomPadding),
      ],
    );
  }
}
