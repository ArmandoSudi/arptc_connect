import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assets_configuration_providers.dart';
import '../assets_configuration_strings.dart';
import '../widgets/assets_configuration_overview_view.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';

class AssetsConfigurationOverviewScreen extends ConsumerWidget {
  const AssetsConfigurationOverviewScreen({
    super.key,
    this.onBack,
    this.onMyAssets,
    this.onAssetRegister,
    this.onStock,
    this.onLicences,
    this.onSuppliersWarranties,
    this.onCmdb,
  });

  final VoidCallback? onBack;
  final VoidCallback? onMyAssets;
  final VoidCallback? onAssetRegister;
  final VoidCallback? onStock;
  final VoidCallback? onLicences;
  final VoidCallback? onSuppliersWarranties;
  final VoidCallback? onCmdb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(assetsConfigurationAccessProvider);
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationShell(
      title: strings.moduleTitle,
      subtitle: strings.moduleSubtitle,
      onBack: onBack,
      child: AssetsConfigurationAsyncView<AssetsConfigurationAccess>(
        value: access,
        data: (value) => AssetsConfigurationOverviewView(
          canOperate: value.canOperate,
          onMyAssets: value.canReadMyAssets ? onMyAssets : null,
          onAssetRegister: onAssetRegister,
          onStock: onStock,
          onLicences: onLicences,
          onSuppliersWarranties: onSuppliersWarranties,
          onCmdb: onCmdb,
        ),
      ),
    );
  }
}
