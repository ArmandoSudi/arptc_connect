import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';

class AssetsConfigurationShell extends StatelessWidget {
  const AssetsConfigurationShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.actions = const [],
    this.onBack,
    this.maxWidth = 1320,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
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
                    theme.colorScheme.primaryContainer.withOpacity(0.64),
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
                      if (onBack != null) ...[
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: PageHeader(title: title, description: subtitle),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
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
              child: ContentView(maxWidth: maxWidth, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class AssetsConfigurationPanel extends StatelessWidget {
  const AssetsConfigurationPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.corporateTheme;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      shadowColor: tokens.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
