import 'package:arptc_connect/modules/service/module_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModuleCard extends StatelessWidget {
  const ModuleCard({
    required this.module,
    super.key,
  });

  final ModuleInfo module;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToModule(context, module.module),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  module.icon,
                  size: 40,
                  color: module.color,
                ),
              ),
              const SizedBox(height: 12),

              // Module Name
              Text(
                module.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                module.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, AppModule module) {
    context.go('/service/${module.routeSegment}');
  }
}
