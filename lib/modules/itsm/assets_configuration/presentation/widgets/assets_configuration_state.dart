import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assets_configuration_contracts.dart';
import '../assets_configuration_strings.dart';

class AssetsConfigurationAsyncView<T> extends StatelessWidget {
  const AssetsConfigurationAsyncView({
    required this.value,
    required this.data,
    super.key,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const _LoadingState(),
      data: data,
      error: (error, _) => _ErrorState(error: error, onRetry: onRetry),
    );
  }
}

class AssetsConfigurationEmptyState extends StatelessWidget {
  const AssetsConfigurationEmptyState({
    required this.title,
    required this.description,
    super.key,
    this.icon = Icons.inventory_2_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: icon,
      title: title,
      description: description,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return Semantics(
      label: strings.loading,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final denied = error is AssetsConfigurationAccessDenied;
    final strings = AssetsConfigurationStrings.of(context);
    return EmptyStateView(
      icon: denied ? Icons.lock_outline : Icons.cloud_off_outlined,
      title: denied ? strings.permissionDenied : strings.unavailable,
      description:
          denied ? strings.permissionDeniedDescription : error.toString(),
      actionLabel: onRetry == null ? null : strings.retry,
      onAction: onRetry,
    );
  }
}
