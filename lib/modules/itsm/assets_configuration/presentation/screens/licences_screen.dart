import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../assets_configuration_strings.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';
import '../widgets/licences_view.dart';
import '../widgets/manager_configuration_dialogs.dart';

class LicencesScreen extends ConsumerWidget {
  const LicencesScreen({
    super.key,
    this.onBack,
    this.onAddLicence,
    this.onLicenceSelected,
    this.limit = 50,
  });

  final VoidCallback? onBack;
  final ManagerDialogAction? onAddLicence;
  final ManagerLicenceDialogAction? onLicenceSelected;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(licencesProvider(limit));
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationShell(
      title: strings.licences,
      subtitle: strings.licencesDescription,
      onBack: onBack,
      actions: [
        FilledButton.icon(
          onPressed:
              onAddLicence == null ? null : () => onAddLicence!(context, ref),
          icon: const Icon(Icons.add),
          label: Text(strings.addLicence),
        ),
      ],
      child: AssetsConfigurationAsyncView<List<LicenceSummary>>(
        value: records,
        onRetry: () => ref.invalidate(licencesProvider(limit)),
        data: (items) => LicencesView(
          licences: items,
          onSelected: onLicenceSelected == null
              ? null
              : (licence) => onLicenceSelected!(context, ref, licence),
        ),
      ),
    );
  }
}
