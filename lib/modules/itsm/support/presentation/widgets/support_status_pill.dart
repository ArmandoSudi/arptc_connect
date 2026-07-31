import 'package:arptc_connect/core/theme.dart';
import 'package:flutter/material.dart';

enum SupportStatusTone {
  neutral,
  info,
  success,
  warning,
  danger,
}

class SupportStatusPill extends StatelessWidget {
  const SupportStatusPill({
    required this.label,
    super.key,
    this.tone = SupportStatusTone.neutral,
    this.icon,
  });

  final String label;
  final SupportStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;
    final colors = switch (tone) {
      SupportStatusTone.neutral => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        ),
      SupportStatusTone.info => (
          tokens.infoContainer,
          tokens.onInfoContainer,
        ),
      SupportStatusTone.success => (
          tokens.successContainer,
          tokens.onSuccessContainer,
        ),
      SupportStatusTone.warning => (
          tokens.warningContainer,
          tokens.onWarningContainer,
        ),
      SupportStatusTone.danger => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
        ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colors.$2),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.$2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
