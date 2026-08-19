import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserManagementMainScreen extends ConsumerWidget {
  const UserManagementMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final policy = ref.watch(userManagementAccessPolicyProvider);
    final supervisorMenus = [
      _UserManagementMenu(
        title: l10n.lookup('umOrganizations'),
        subtitle: l10n.lookup('umOrganizationsDescription'),
        icon: Icons.corporate_fare_outlined,
        color: const Color(0xFF0D47A1),
        path: '/service/usermanagement/organizations',
      ),
      _UserManagementMenu(
        title: l10n.lookup('umStructure'),
        subtitle: l10n.lookup('umStructureDescription'),
        icon: Icons.account_tree_outlined,
        color: const Color(0xFF00695C),
        path: '/service/usermanagement/structure',
      ),
      _UserManagementMenu(
        title: l10n.lookup('umAgents'),
        subtitle: l10n.lookup('umAgentsDescription'),
        icon: Icons.badge_outlined,
        color: const Color(0xFFAD5700),
        path: '/service/usermanagement/agents',
      ),
      _UserManagementMenu(
        title: l10n.lookup('umModules'),
        subtitle: l10n.lookup('umModulesDescription'),
        icon: Icons.extension_outlined,
        color: const Color(0xFF5D4037),
        path: '/service/usermanagement/modules',
      ),
    ];
    final menus = policy.canReadPrivateProfiles
        ? supervisorMenus
        : supervisorMenus
            .where((menu) => menu.path.endsWith('/agents'))
            .toList(growable: false);

    return UserManagementAccessGate(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.lookup('umTitle'))),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lookup('umTitle'),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(l10n.lookup('umSubtitle')),
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = _columnCount(constraints.maxWidth);
                      return GridView.builder(
                        itemCount: menus.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio:
                              constraints.maxWidth < 600 ? 1.15 : 1.5,
                        ),
                        itemBuilder: (context, index) {
                          final menu = menus[index];
                          return _MenuCard(
                            menu: menu,
                            onTap: () => context.go(menu.path),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _columnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.menu,
    required this.onTap,
  });

  final _UserManagementMenu menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: menu.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  menu.icon,
                  color: menu.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                menu.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                menu.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserManagementMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String path;

  const _UserManagementMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.path,
  });
}
