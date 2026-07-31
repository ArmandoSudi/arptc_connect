import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_overview_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItsmSectionOverviewScreen extends StatelessWidget {
  const ItsmSectionOverviewScreen({
    required this.section,
    super.key,
  });

  final ItsmSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return ItsmOverviewView.section(
      title: section.title(l10n),
      subtitle: section.description(l10n),
      section: section,
      onFeaturePressed: (feature) => context.go(feature.routeFor(section)),
    );
  }
}
