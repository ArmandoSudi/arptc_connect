import 'package:arptc_connect/modules/social/screens/user_social_screen.dart';
import 'package:flutter/material.dart';

import '../modules/administration/presentation/screens/administration_screen.dart';

enum Modules { social, inventory, helpDesk, administration }

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final _services = [
    Services(
      name: "Social",
      icon: Icons.people_alt_outlined,
      filledIcon: Icons.people_alt,
      module: Modules.social,
      color: Colors.purple,
    ),
    Services(
      name: "Inventory",
      icon: Icons.inventory_2_outlined,
      filledIcon: Icons.inventory_2,
      module: Modules.inventory,
      color: Colors.blue,
    ),
    Services(
      name: "Help Desk",
      icon: Icons.support_agent_outlined,
      filledIcon: Icons.support_agent,
      module: Modules.helpDesk,
      color: Colors.orange,
    ),
    Services(
      name: "Administration",
      icon: Icons.admin_panel_settings_outlined,
      filledIcon: Icons.admin_panel_settings,
      module: Modules.administration,
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Services"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: _services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final service = _services[index];
              return _ServiceCard(
                service: service,
                onTap: () => _navigateToModule(context, service.module),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, Modules module) {
    switch (module) {
      case Modules.social:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const UserSocialScreen()),
        );
        break;
      case Modules.inventory:
        debugPrint("inventory");
        break;
      case Modules.helpDesk:
        debugPrint("helpDesk");
        break;
      case Modules.administration:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AdministrationScreen()),
        );
        break;
    }
  }
}

/// Material Design 3 Service Card
///
/// A tappable card with icon and label for module navigation
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onTap,
  });

  final Services service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                service.color.withOpacity(0.1),
                service.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  service.icon,
                  size: 40,
                  color: service.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Services {
  final String name;
  final IconData icon;
  final IconData filledIcon;
  final Modules module;
  final Color color;

  Services({
    required this.name,
    required this.icon,
    required this.filledIcon,
    required this.module,
    required this.color,
  });
}
