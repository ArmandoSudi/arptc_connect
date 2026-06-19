import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Material Design 3 Page Header
///
/// A consistent header component for pages with:
/// - Large, prominent title
/// - Optional description text
/// - Proper typography scale
class PageHeaderSimple extends StatelessWidget {
  const PageHeaderSimple({
    super.key,
    required this.title,
    this.backButton = true,
    this.backRoute = '/service',
    this.actions,
  });

  final String title;
  final bool backButton;
  final String backRoute;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (backButton)
          IconButton(
            tooltip: S.of(context).back,
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => _goBack(context, backRoute),
          ),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ), /**/
          ),
        ),
        if (actions != null) ...[
          const SizedBox(width: 16),
          ...actions!,
        ],
      ],
    );
  }

  void _goBack(BuildContext context, String fallbackRoute) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackRoute);
  }
}
