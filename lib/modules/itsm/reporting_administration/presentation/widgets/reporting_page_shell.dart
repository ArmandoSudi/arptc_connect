import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';

class ReportingPageShell extends StatelessWidget {
  const ReportingPageShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primaryContainer.withOpacity(.68),
                    colors.surface
                  ],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: ContentView(
                  maxWidth: 1360,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final heading = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (onBack != null)
                          IconButton(
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        Expanded(
                            child: PageHeader(
                                title: title, description: subtitle)),
                      ],
                    );
                    if (constraints.maxWidth < 700) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading,
                          if (actions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: actions),
                          ],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: heading),
                        if (actions.isNotEmpty)
                          Wrap(spacing: 8, children: actions),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 40),
            sliver: SliverToBoxAdapter(
              child: ContentView(maxWidth: 1360, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportingPanel extends StatelessWidget {
  const ReportingPanel({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || trailing != null)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(title!,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        if (subtitle != null)
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            if (title != null || trailing != null) const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
