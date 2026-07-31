import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_navigation_card.dart';
import 'package:flutter/material.dart';

class ItsmNavigationGrid extends StatelessWidget {
  const ItsmNavigationGrid.sections({
    required List<ItsmSection> sections,
    required this.onSectionPressed,
    super.key,
  })  : _sections = sections,
        _features = null,
        section = null,
        onFeaturePressed = null;

  const ItsmNavigationGrid.features({
    required ItsmSection this.section,
    required List<ItsmFeature> features,
    required this.onFeaturePressed,
    super.key,
  })  : _sections = null,
        _features = features,
        onSectionPressed = null;

  final List<ItsmSection>? _sections;
  final List<ItsmFeature>? _features;
  final ItsmSection? section;
  final ValueChanged<ItsmSection>? onSectionPressed;
  final ValueChanged<ItsmFeature>? onFeaturePressed;

  static int columnCountForWidth(double width) {
    if (width < 650) {
      return 1;
    }
    if (width < 1100) {
      return 2;
    }
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = columnCountForWidth(constraints.maxWidth);
        final count = _sections?.length ?? _features!.length;
        return GridView.builder(
          key: const ValueKey('itsm-navigation-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: columnCount == 1 ? 2 : 1.25,
          ),
          itemBuilder: (context, index) {
            final sections = _sections;
            if (sections != null) {
              final item = sections[index];
              return ItsmNavigationCard(
                cardKey: ValueKey('itsm-section-${item.name}'),
                title: item.title(l10n),
                description: item.description(l10n),
                icon: item.icon,
                color: item.color,
                onPressed: () => onSectionPressed!(item),
              );
            }

            final item = _features![index];
            final parent = section!;
            return ItsmNavigationCard(
              cardKey: ValueKey('itsm-feature-${item.name}'),
              title: item.title(l10n),
              description: l10n.itsmFeatureCardDescription,
              icon: item.icon,
              color: parent.color,
              onPressed: () => onFeaturePressed!(item),
            );
          },
        );
      },
    );
  }
}
