import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/content_view.dart';
import '../../../../widgets/page_header.dart';

/// Administration Screen
///
/// Main entry point for administrative functions following M3 guidelines
class AdministrationScreen extends StatelessWidget {
  AdministrationScreen({super.key});

  final entities = [
    _EntityItem(
      title: "Directions",
      route: "directions",
      icon: Icons.business_outlined,
      description: "Manage organizational directions",
    ),
    _EntityItem(
      title: "Services",
      route: "services",
      icon: Icons.miscellaneous_services_outlined,
      description: "Manage services within directions",
    ),
    _EntityItem(
      title: "Bureaux",
      route: "bureaux",
      icon: Icons.meeting_room_outlined,
      description: "Manage office locations",
    ),
    _EntityItem(
      title: "Agents",
      route: "agents",
      icon: Icons.people_outline,
      description: "Manage employee records",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
      ),
      body: ContentView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Administration',
              description: 'Gérer les directions, services, bureaux et agents',
            ),
            const Gap(24),
            Expanded(
              child: ListView.separated(
                itemCount: entities.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final entity = entities[index];
                  return _EntityCard(
                    entity: entity,
                    onTap: () => context.go("/administration/${entity.route}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityItem {
  final String title;
  final String route;
  final IconData icon;
  final String description;

  _EntityItem({
    required this.title,
    required this.route,
    required this.icon,
    required this.description,
  });
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.entity,
    required this.onTap,
  });

  final _EntityItem entity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  entity.icon,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      entity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
