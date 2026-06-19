import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/navigation_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    Key? key,
    required this.navigationShell,
  }) : super(
            key: key ?? const ValueKey<String>('ScaffoldWithNestedNavigation'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active. This example demonstrates how to support this behavior,
      // using the initialLocation parameter of goBranch.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 960) {
        // print("Constraints width : ${constraints.maxWidth} : NAVIGATION BAR");

        return ScaffoldWithNavigationBar(
          body: navigationShell,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
        );
      } else {
        // print("Constraints width : ${constraints.maxWidth} : NAVIGATION RAIL");

        return ScaffoldWithNavigationRail(
          body: navigationShell,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
        );
      }
    });
  }
}

class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      appBar: const NavigationAppBar(),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: [
          NavigationDestination(
            label: l10n.navigationHome,
            icon: const Icon(Icons.home_filled),
          ),
          NavigationDestination(
            label: l10n.navigationServices,
            icon: const Icon(Icons.apps),
          ),
          NavigationDestination(
            label: l10n.navigationCourrier,
            icon: const Icon(Icons.mail_outline),
          ),
          NavigationDestination(
            label: l10n.navigationDashboard,
            icon: const Icon(Icons.dashboard_outlined),
          ),
          NavigationDestination(
            label: l10n.navigationProfile,
            icon: const Icon(Icons.person_outline),
          ),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

class ScaffoldWithNavigationRail extends StatelessWidget {
  const ScaffoldWithNavigationRail({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      appBar: const NavigationAppBar(),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                label: Text(l10n.navigationHome),
                icon: const Icon(Icons.home_filled),
              ),
              NavigationRailDestination(
                label: Text(l10n.navigationServices),
                icon: const Icon(Icons.apps),
              ),
              NavigationRailDestination(
                label: Text(l10n.navigationCourriers),
                icon: const Icon(Icons.mail_outline),
              ),
              NavigationRailDestination(
                label: Text(l10n.navigationDashboard),
                icon: const Icon(Icons.dashboard_outlined),
              ),
              NavigationRailDestination(
                label: Text(l10n.navigationProfile),
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
}
