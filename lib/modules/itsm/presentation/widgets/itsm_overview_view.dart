import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_navigation_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItsmOverviewView extends StatelessWidget {
  const ItsmOverviewView.landing({
    required this.title,
    required this.subtitle,
    required this.onSectionPressed,
    super.key,
  })  : section = null,
        onFeaturePressed = null;

  const ItsmOverviewView.section({
    required this.title,
    required this.subtitle,
    required ItsmSection this.section,
    required this.onFeaturePressed,
    super.key,
  }) : onSectionPressed = null;

  final String title;
  final String subtitle;
  final ItsmSection? section;
  final ValueChanged<ItsmSection>? onSectionPressed;
  final ValueChanged<ItsmFeature>? onFeaturePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.55),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          tooltip: S.of(context).back,
                          onPressed: () => _goBack(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(tokens.panelRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: section == null
                        ? ItsmNavigationGrid.sections(
                            sections: ItsmSection.values,
                            onSectionPressed: onSectionPressed!,
                          )
                        : ItsmNavigationGrid.features(
                            section: section!,
                            features: section!.features,
                            onFeaturePressed: onFeaturePressed!,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(section == null ? '/service' : ItsmRoutes.root);
  }
}
