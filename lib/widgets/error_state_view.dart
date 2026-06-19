import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Material Design 3 Error State Widget
///
/// A reusable error state view with:
/// - Error icon
/// - Title
/// - Optional description
/// - Retry action button
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    this.description,
    this.onRetry,
    this.retryLabel,
  });

  final String title;
  final String? description;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = S.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 8),
                    Text(retryLabel ?? l10n.retry),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
