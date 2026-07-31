import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';

class SecurityComplianceShell extends StatelessWidget {
  const SecurityComplianceShell({
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
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.6),
                    theme.colorScheme.surface,
                  ],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: ContentView(
                  maxWidth: 1320,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final header = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (onBack != null) ...[
                            IconButton(
                              onPressed: onBack,
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
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
                        ],
                      );
                      final actionBar = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: actions,
                      );
                      if (constraints.maxWidth < 720 && actions.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            const SizedBox(height: 16),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: actionBar,
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: header),
                          if (actions.isNotEmpty) ...[
                            const SizedBox(width: 20),
                            Flexible(child: actionBar),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 40),
            sliver: SliverToBoxAdapter(
              child: ContentView(maxWidth: 1320, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityComplianceCard extends StatelessWidget {
  const SecurityComplianceCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      shadowColor: tokens.cardShadow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null || trailing != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(subtitle!),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              if (title != null || subtitle != null || trailing != null)
                const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
