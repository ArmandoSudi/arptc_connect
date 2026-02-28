import 'package:flutter/material.dart';

/// Material Design 3 Navigation Bar
///
/// Uses NavigationBar with proper M3 styling including:
/// - Filled indicator for selected item
/// - Proper icon and label colors
/// - Animated transitions
class CustomNavBar extends StatelessWidget {
  final int curTabIndex;
  final Function(int) onTap;
  const CustomNavBar(Key? key, this.onTap, this.curTabIndex) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: curTabIndex,
      onDestinationSelected: onTap,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
