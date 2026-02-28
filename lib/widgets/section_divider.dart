import 'package:flutter/material.dart';

/// Material Design 3 Section Divider
///
/// A labeled divider for separating content sections
class SectionDivider extends StatelessWidget {
  const SectionDivider({
    super.key,
    this.label,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  final String? label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (label == null) {
      return Padding(
        padding: padding,
        child: Divider(color: colorScheme.outlineVariant),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colorScheme.outlineVariant),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}
