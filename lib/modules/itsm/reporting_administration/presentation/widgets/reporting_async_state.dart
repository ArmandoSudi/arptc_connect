import 'package:flutter/material.dart';
import '../reporting_administration_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportingAsyncState<T> extends StatelessWidget {
  const ReportingAsyncState({
    required this.value,
    required this.data,
    required this.loadingLabel,
    required this.errorLabel,
    required this.emptyLabel,
    super.key,
    this.isEmpty,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final bool Function(T value)? isEmpty;
  final String loadingLabel;
  final String errorLabel;
  final String emptyLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        loading: () => _Message(
            icon: Icons.sync_rounded, label: loadingLabel, progress: true),
        error: (_, __) => _Message(
            icon: Icons.error_outline_rounded,
            label: errorLabel,
            onRetry: onRetry),
        data: (value) => isEmpty?.call(value) == true
            ? _Message(icon: Icons.inbox_outlined, label: emptyLabel)
            : data(value),
      );
}

class ReportingAccessDenied extends StatelessWidget {
  const ReportingAccessDenied(
      {required this.title, required this.description, super.key});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => _Message(
        icon: Icons.lock_outline_rounded,
        label: title,
        description: description,
      );
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon,
      required this.label,
      this.description,
      this.progress = false,
      this.onRetry});
  final IconData icon;
  final String label;
  final String? description;
  final bool progress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (progress)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 42),
              const SizedBox(height: 12),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(description!, textAlign: TextAlign.center),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      ReportingAdministrationStrings.of(context).value('retry'),
                    )),
              ],
            ],
          ),
        ),
      );
}
