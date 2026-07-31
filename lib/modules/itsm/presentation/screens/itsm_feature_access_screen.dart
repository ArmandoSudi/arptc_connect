import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_access_state.dart';
import 'package:flutter/material.dart';

class ItsmFeatureAccessScreen extends StatelessWidget {
  const ItsmFeatureAccessScreen({
    required this.section,
    required this.feature,
    super.key,
  });

  final ItsmSection section;
  final ItsmFeature feature;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return ItsmAccessState(
      title: feature.title(l10n),
      description: l10n.itsmFeatureUnavailableDescription,
      backLabel: section.title(l10n),
      backRoute: section.route,
      icon: feature.icon,
    );
  }
}
