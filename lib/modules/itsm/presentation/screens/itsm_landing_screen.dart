import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_overview_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ItsmLandingScreen extends StatelessWidget {
  const ItsmLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return ItsmOverviewView.landing(
      title: l10n.itsmLandingTitle,
      subtitle: l10n.itsmLandingDescription,
      onSectionPressed: (section) => context.go(section.route),
    );
  }
}
