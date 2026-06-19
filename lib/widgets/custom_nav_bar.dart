import 'package:arptc_connect/generated/l10n.dart';
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
    final l10n = S.of(context);

    return NavigationBar(
      selectedIndex: curTabIndex,
      onDestinationSelected: onTap,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: l10n.navigationDashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.navigationHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.navigationAccount,
        ),
      ],
    );
  }
}
