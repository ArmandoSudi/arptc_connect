import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItsmAccessState extends StatelessWidget {
  const ItsmAccessState({
    required this.title,
    required this.description,
    required this.backLabel,
    required this.backRoute,
    this.icon = Icons.lock_clock_outlined,
    super.key,
  });

  final String title;
  final String description;
  final String backLabel;
  final String backRoute;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 38,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => context.go(backRoute),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(backLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
