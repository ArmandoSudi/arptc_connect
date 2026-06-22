import 'package:arptc_connect/core/theme.dart';
import 'package:flutter/material.dart';

/// Material Design 3 Status Chip
///
/// A chip component for displaying status information
/// with semantic colors based on status type
enum StatusType {
  success,
  warning,
  error,
  info,
  neutral,
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  final String label;
  final StatusType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.corporateTheme;

    final (bgColor, textColor) = _getColors(colorScheme, tokens);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getColors(
    ColorScheme colorScheme,
    CorporateThemeTokens tokens,
  ) {
    switch (type) {
      case StatusType.success:
        return (tokens.successContainer, tokens.onSuccessContainer);
      case StatusType.warning:
        return (tokens.warningContainer, tokens.onWarningContainer);
      case StatusType.error:
        return (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        );
      case StatusType.info:
        return (tokens.infoContainer, tokens.onInfoContainer);
      case StatusType.neutral:
        return (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        );
    }
  }
}
