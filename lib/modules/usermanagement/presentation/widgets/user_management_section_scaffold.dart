import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserManagementSectionScaffold extends ConsumerWidget {
  const UserManagementSectionScaffold({
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.body,
    this.primaryAction,
    this.primaryActionIsNavigation = false,
    super.key,
  });

  final int selectedIndex;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? primaryAction;
  final bool primaryActionIsNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(userManagementAccessPolicyProvider);
    final destinations = policy.canReadPrivateProfiles
        ? _ManagementDestination.all
        : const [_ManagementDestination.agents];
    final selectedDestination = destinations.indexWhere(
      (destination) => destination.sectionIndex == selectedIndex,
    );
    final visibleSelectedIndex =
        selectedDestination < 0 ? 0 : selectedDestination;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(
                  title: title,
                  subtitle: subtitle,
                  primaryAction:
                      policy.canManageOrganization || primaryActionIsNavigation
                          ? primaryAction
                          : null,
                ),
                if (policy.isReadOnlySupervisor) const _ReadOnlyBanner(),
                if (!wide)
                  _CompactDestinations(
                    destinations: destinations,
                    selectedIndex: visibleSelectedIndex,
                    onSelected: (index) =>
                        context.go(destinations[index].route),
                  ),
                Expanded(child: body),
              ],
            );
            if (!wide) return content;
            if (destinations.length < 2) return content;
            return Row(
              children: [
                _ManagementRail(
                  destinations: destinations,
                  selectedIndex: visibleSelectedIndex,
                  onSelected: (index) => context.go(destinations[index].route),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.primaryAction,
  });

  final String title;
  final String subtitle;
  final Widget? primaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (primaryAction != null) ...[
            const SizedBox(width: 16),
            primaryAction!,
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, color: colors.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lookup('umReadOnlyAccess'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(l10n.lookup('umReadOnlyDescription')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementRail extends StatelessWidget {
  const _ManagementRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ManagementDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return NavigationRail(
      selectedIndex: selectedIndex,
      extended: MediaQuery.sizeOf(context).width >= 1180,
      onDestinationSelected: onSelected,
      labelType: MediaQuery.sizeOf(context).width >= 1180
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      destinations: destinations
          .map((destination) => NavigationRailDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: Text(destination.label(l10n)),
              ))
          .toList(growable: false),
    );
  }
}

class _CompactDestinations extends StatelessWidget {
  const _CompactDestinations({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ManagementDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(destinations.length, (index) {
          final destination = destinations[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selectedIndex == index,
              onSelected: (_) => onSelected(index),
              avatar: Icon(destination.icon, size: 18),
              label: Text(destination.label(l10n)),
            ),
          );
        }),
      ),
    );
  }
}

class _ManagementDestination {
  const _ManagementDestination({
    required this.sectionIndex,
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  final int sectionIndex;
  final String route;
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;

  String label(S l10n) => l10n.lookup(labelKey);

  static const organizations = _ManagementDestination(
    sectionIndex: 0,
    route: '/service/usermanagement/organizations',
    labelKey: 'umOrganizations',
    icon: Icons.corporate_fare_outlined,
    selectedIcon: Icons.corporate_fare,
  );
  static const structure = _ManagementDestination(
    sectionIndex: 1,
    route: '/service/usermanagement/structure',
    labelKey: 'umStructure',
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree,
  );
  static const agents = _ManagementDestination(
    sectionIndex: 2,
    route: '/service/usermanagement/agents',
    labelKey: 'umAgents',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
  );
  static const modules = _ManagementDestination(
    sectionIndex: 3,
    route: '/service/usermanagement/modules',
    labelKey: 'umModules',
    icon: Icons.widgets_outlined,
    selectedIcon: Icons.widgets,
  );

  static const all = [organizations, structure, agents, modules];
}
