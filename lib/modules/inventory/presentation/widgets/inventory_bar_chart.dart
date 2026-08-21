import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

import 'inventory_shell.dart';

class InventoryBarChart extends StatelessWidget {
  const InventoryBarChart({
    required this.title,
    required this.data,
    super.key,
  });

  final String title;
  final Map<String, num> data;

  @override
  Widget build(BuildContext context) {
    final entries =
        data.entries.where((entry) => entry.value > 0).toList(growable: false);
    final maximum = entries.fold<num>(
        0, (value, entry) => entry.value > value ? entry.value : value);
    return InventoryPanel(
      title: title,
      child: entries.isEmpty
          ? SizedBox(
              height: 180,
              child: Center(
                child: Text(S.of(context).noDataAvailable),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  _Bar(
                    label: entries[index].key,
                    value: entries[index].value,
                    maximum: maximum,
                    color: context.corporateTheme.chartPalette[
                        index % context.corporateTheme.chartPalette.length],
                  ),
                  if (index != entries.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.maximum,
    required this.color,
  });

  final String label;
  final num value;
  final num maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ),
            Text(
              value.toString(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                height: 12,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              FractionallySizedBox(
                widthFactor:
                    maximum == 0 ? 0 : (value / maximum).clamp(0, 1).toDouble(),
                child: Container(height: 12, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
