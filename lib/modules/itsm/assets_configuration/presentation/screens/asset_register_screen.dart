import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../../domain/asset_parameter.dart';
import '../assets_configuration_strings.dart';
import '../widgets/asset_register_dialogs.dart';
import '../widgets/asset_views.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';

typedef AssetRegisterAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
);

class AssetRegisterScreen extends ConsumerStatefulWidget {
  const AssetRegisterScreen({
    super.key,
    required this.onAssetSelected,
    this.onBack,
    this.onRegisterAsset = showAssetRegistrationDialog,
    this.onManageParameters,
    this.resultLimit = PageRequest.maximumLimit,
  });

  final ValueChanged<AssetSummary> onAssetSelected;
  final VoidCallback? onBack;
  final AssetRegisterAction? onRegisterAsset;
  final VoidCallback? onManageParameters;
  final int resultLimit;

  @override
  ConsumerState<AssetRegisterScreen> createState() =>
      _AssetRegisterScreenState();
}

class _AssetRegisterScreenState extends ConsumerState<AssetRegisterScreen> {
  String _search = '';
  String? _categoryId;
  String? _brand;
  AssetAvailability? _availability;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _search = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final request = AssetRegisterRequest(limit: widget.resultLimit);
    final assets = ref.watch(assetRegisterProvider(request));
    final parameterValue = ref
            .watch(assetParametersProvider(PageRequest.maximumLimit))
            .asData
            ?.value ??
        const <AssetParameter>[];
    return AssetsConfigurationShell(
      title: strings.assetRegister,
      subtitle: strings.assetRegisterDescription,
      onBack: widget.onBack,
      actions: [
        OutlinedButton.icon(
          onPressed: widget.onManageParameters,
          icon: const Icon(Icons.tune_outlined),
          label: Text(strings.assetParameters),
        ),
        FilledButton.icon(
          onPressed: widget.onRegisterAsset == null
              ? null
              : () => widget.onRegisterAsset!(context, ref),
          icon: const Icon(Icons.add),
          label: Text(strings.registerAsset),
        ),
      ],
      child: AssetsConfigurationAsyncView<List<AssetSummary>>(
        value: assets,
        onRetry: () => ref.invalidate(assetRegisterProvider(request)),
        data: (items) {
          final categories = _categoryOptions(items, parameterValue);
          final brands = items
              .map((asset) => asset.brand.trim())
              .where((brand) => brand.isNotEmpty)
              .toSet()
              .toList(growable: false)
            ..sort((left, right) =>
                left.toLowerCase().compareTo(right.toLowerCase()));
          final visible = items.where((asset) {
            final matchesCategory = _categoryId == null ||
                asset.categoryId == _categoryId ||
                (asset.categoryId.isEmpty &&
                    asset.categoryName == categories[_categoryId]);
            final matchesBrand = _brand == null ||
                asset.brand.toLowerCase() == _brand!.toLowerCase();
            final matchesAvailability =
                _availability == null || asset.availability == _availability;
            final matchesSearch = _search.isEmpty ||
                asset.assetTag.toLowerCase().contains(_search) ||
                asset.name.toLowerCase().contains(_search) ||
                asset.brand.toLowerCase().contains(_search) ||
                asset.model.toLowerCase().contains(_search) ||
                asset.serialNumber.toLowerCase().contains(_search) ||
                asset.productNumber.toLowerCase().contains(_search);
            return matchesCategory &&
                matchesBrand &&
                matchesAvailability &&
                matchesSearch;
          }).toList(growable: false);
          return AssetRegisterView(
            assets: visible,
            categoryOptions: categories,
            brandOptions: brands,
            selectedCategoryId: _categoryId,
            selectedBrand: _brand,
            selectedAvailability: _availability,
            onCategoryChanged: (value) => setState(() => _categoryId = value),
            onBrandChanged: (value) => setState(() => _brand = value),
            onAvailabilityChanged: (value) =>
                setState(() => _availability = value),
            onSearchChanged: _searchChanged,
            onSelected: widget.onAssetSelected,
          );
        },
      ),
    );
  }

  Map<String, String> _categoryOptions(
    List<AssetSummary> assets,
    List<AssetParameter> parameters,
  ) {
    final options = <String, String>{
      for (final parameter in parameters)
        if (parameter.type == AssetParameterType.category)
          parameter.id: parameter.name,
    };
    for (final asset in assets) {
      if (asset.categoryId.isNotEmpty && asset.categoryName.isNotEmpty) {
        options.putIfAbsent(asset.categoryId, () => asset.categoryName);
      }
    }
    final entries = options.entries.toList(growable: false)
      ..sort((left, right) =>
          left.value.toLowerCase().compareTo(right.value.toLowerCase()));
    return Map.fromEntries(entries);
  }
}
