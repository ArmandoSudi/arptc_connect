import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityComplianceAsyncState<T> extends StatelessWidget {
  const SecurityComplianceAsyncState({
    required this.value,
    required this.data,
    required this.onRetry,
    required this.loadingLabel,
    required this.errorLabel,
    required this.retryLabel,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback onRetry;
  final String loadingLabel;
  final String errorLabel;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(loadingLabel),
            ],
          ),
        ),
      ),
      error: (_, __) => SecurityComplianceMessageState(
        icon: Icons.error_outline_rounded,
        title: errorLabel,
        actionLabel: retryLabel,
        onAction: onRetry,
      ),
    );
  }
}

class SecurityComplianceMessageState extends StatelessWidget {
  const SecurityComplianceMessageState({
    required this.icon,
    required this.title,
    super.key,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(description!, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
