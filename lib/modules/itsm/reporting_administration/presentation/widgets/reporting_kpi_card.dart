import 'package:flutter/material.dart';

class ReportingKpiCard extends StatelessWidget {
  const ReportingKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
    this.accent,
  });

  final String label;
  final num value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: color)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('$value',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
