import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/components/bottom_nav_bar.dart';
import 'package:hooko_v20/components/ios_modal_sheet.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/state/app_state.dart';

/// InheritedWidget to provide access to the MainShell's scaffold key
class MainShellScope extends InheritedWidget {
  final GlobalKey<IosModalScaffoldState> scaffoldKey;
  
  const MainShellScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  static GlobalKey<IosModalScaffoldState>? of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MainShellScope>();
    return scope?.scaffoldKey;
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => scaffoldKey != oldWidget.scaffoldKey;
}

/// A persistent shell that wraps main screens with a single navbar instance.
/// This ensures the navbar animation works correctly across navigation.
class MainShell extends StatefulWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<IosModalScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Preload history when shell loads (so history screen doesn't blink)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppStateProvider.read(context);
      if (!appState.historyLoaded) {
        appState.loadHistory();
      }
    });
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.history)) return 1;
    if (location.startsWith(AppRoutes.profile)) return 2;
    return 0; // home
  }

  void _handleNavTap(int index) {
    final currentIndex = _getSelectedIndex(context);
    if (index == currentIndex) return;
    
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

  String? _getBackgroundImage(int index) {
    switch (index) {
      case 1:
        return 'assets/images/history.jpg';
      case 2:
        return null; // No background for profile
      default:
        return 'assets/images/tree.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 6;
    final selectedIndex = _getSelectedIndex(context);
    final backgroundImage = _getBackgroundImage(selectedIndex);
    
    return MainShellScope(
      scaffoldKey: _scaffoldKey,
      child: IosModalScaffold(
        key: _scaffoldKey,
        staticBackground: backgroundImage != null
            ? Center(child: Image.asset(backgroundImage, fit: BoxFit.cover))
            : null,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(child: widget.child),
                BottomNavBar(
                  selectedIndex: selectedIndex,
                  onTap: _handleNavTap,
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
