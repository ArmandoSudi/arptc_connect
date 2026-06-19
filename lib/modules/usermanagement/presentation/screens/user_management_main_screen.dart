import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserManagementMainScreen extends StatelessWidget {
  const UserManagementMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const menus = [
      _UserManagementMenu(
        title: 'Agents',
        subtitle: 'Manage agents and assignments',
        icon: Icons.group_outlined,
        color: Color(0xFF4A148C),
        path: '/service/usermanagement/agents',
      ),
      _UserManagementMenu(
        title: 'Bureaux',
        subtitle: 'Manage bureaux by service',
        icon: Icons.business_outlined,
        color: Color(0xFFE65100),
        path: '/service/usermanagement/bureaux',
      ),
      _UserManagementMenu(
        title: 'Services',
        subtitle: 'Manage services by department',
        icon: Icons.workspaces_outline,
        color: Color(0xFF0D47A1),
        path: '/service/usermanagement/services',
      ),
      _UserManagementMenu(
        title: 'Departments',
        subtitle: 'Manage organizational departments',
        icon: Icons.account_tree_outlined,
        color: Color(0xFF1B5E20),
        path: '/service/usermanagement/departments',
      ),

      _UserManagementMenu(
        title: 'Modules',
        subtitle: 'Manage modules and permission roles',
        icon: Icons.extension_outlined,
        color: Color(0xFF00695C),
        path: '/service/usermanagement/modules',
      ),
    ];

    return Scaffold(
      body: ContentView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => context.pop(),
                ),
                const PageHeader(
                  title: 'User Management',
                  description:
                      'Departments, services, bureaux, agents and modules',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = _columnCount(constraints.maxWidth);

                  return GridView.builder(
                    itemCount: menus.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
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
    );
  }

  int _columnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 2;
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
