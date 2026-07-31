import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportPageShell extends StatelessWidget {
  const SupportPageShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.actions = const [],
    this.showBackButton = true,
    this.maxWidth = 1280,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool showBackButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.52),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: ContentView(
                  maxWidth: maxWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showBackButton) ...[
                        IconButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/services/itsm/support');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: PageHeader(
                          title: title,
                          description: subtitle,
                        ),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Flexible(
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: actions,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 40),
            sliver: SliverToBoxAdapter(
              child: ContentView(
                maxWidth: maxWidth,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportPanel extends StatelessWidget {
  const SupportPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.corporateTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: tokens.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
