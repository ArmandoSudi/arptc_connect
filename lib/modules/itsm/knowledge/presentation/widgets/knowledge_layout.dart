import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

class KnowledgePage extends StatelessWidget {
  const KnowledgePage({
    required this.title,
    required this.child,
    super.key,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: S.of(context).back,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
                vertical: 24,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class KnowledgePanel extends StatelessWidget {
  const KnowledgePanel({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class KnowledgeResponsiveGrid extends StatelessWidget {
  const KnowledgeResponsiveGrid({
    required this.children,
    super.key,
    this.minimumWidth = 300,
    this.maximumColumns = 3,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minimumWidth;
  final int maximumColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final possible =
            ((constraints.maxWidth + spacing) / (minimumWidth + spacing))
                .floor();
        final columns = possible.clamp(1, maximumColumns);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class KnowledgeAsyncState extends StatelessWidget {
  const KnowledgeAsyncState({
    required this.icon,
    required this.title,
    super.key,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final bool isLoading;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return KnowledgePanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 42),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
