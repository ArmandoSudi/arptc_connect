import 'package:arptc_connect/core/theme.dart';
import 'package:flutter/material.dart';

/// Reusable enterprise surface for dashboards and module sections.
class CorporateSurfaceCard extends StatelessWidget {
  const CorporateSurfaceCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.accentColor,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final String? title;
  final String? subtitle;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accentColor != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          if (title != null)
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (title != null || subtitle != null) const SizedBox(height: 18),
          child,
        ],
      ),
    );

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      shadowColor: tokens.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              child: content,
            ),
    );
  }
}

/// Reusable KPI card for operational and executive dashboards.
class CorporateKpiCard extends StatelessWidget {
  const CorporateKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
    this.subtitle,
    this.accentColor,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return CorporateSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
