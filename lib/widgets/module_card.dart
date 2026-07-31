import 'package:arptc_connect/core/theme.dart';
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
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;

    return Card(
      child: InkWell(
        onTap: () => _navigateToModule(context, module.module),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  module.icon,
                  size: 32,
                  color: module.color,
                ),
              ),
              const SizedBox(height: 16),

              // Module Name
              Text(
                module.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description
              Expanded(
                child: Text(
                  module.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, AppModule module) {
    context.go(module.routePath);
  }
}
