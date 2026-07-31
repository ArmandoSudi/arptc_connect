import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../assets_configuration_strings.dart';
import '../widgets/asset_views.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';

class MyAssetsScreen extends ConsumerStatefulWidget {
  const MyAssetsScreen({
    super.key,
    this.onBack,
    required this.onAssetSelected,
    this.limit = 25,
  });

  final VoidCallback? onBack;
  final ValueChanged<AssetSummary> onAssetSelected;
  final int limit;

  @override
  ConsumerState<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends ConsumerState<MyAssetsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(myAssetsProvider(widget.limit));
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationShell(
      title: strings.myAssets,
      subtitle: strings.myAssetsDescription,
      onBack: widget.onBack,
      child: AssetsConfigurationAsyncView<List<AssetSummary>>(
        value: assets,
        onRetry: () => ref.invalidate(myAssetsProvider(widget.limit)),
        data: (items) => MyAssetsView(
          assets: items,
          searchQuery: _search,
          onSearchChanged: (value) => setState(() => _search = value),
          onSelected: widget.onAssetSelected,
        ),
      ),
    );
  }
}
