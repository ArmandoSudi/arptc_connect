import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../assets_configuration_strings.dart';
import '../widgets/asset_views.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';
import '../widgets/manager_configuration_dialogs.dart';

class AssetRegisterScreen extends ConsumerStatefulWidget {
  const AssetRegisterScreen({
    super.key,
    required this.onAssetSelected,
    this.onBack,
    this.onRegisterAsset,
    this.pageSize = 25,
  });

  final ValueChanged<AssetSummary> onAssetSelected;
  final VoidCallback? onBack;
  final ManagerDialogAction? onRegisterAsset;
  final int pageSize;

  @override
  ConsumerState<AssetRegisterScreen> createState() =>
      _AssetRegisterScreenState();
}

class _AssetRegisterScreenState extends ConsumerState<AssetRegisterScreen> {
  String _search = '';
  PageCursor? _cursor;
  PageCursor? _previousCursor;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _search = value;
        _cursor = null;
        _previousCursor = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final request = AssetPageRequest(
      query: AssetListQuery(search: _search),
      page: PageRequest(limit: widget.pageSize, cursor: _cursor),
    );
    final page = ref.watch(assetPageProvider(request));
    return AssetsConfigurationShell(
      title: strings.assetRegister,
      subtitle: strings.assetRegisterDescription,
      onBack: widget.onBack,
      actions: [
        FilledButton.icon(
          onPressed: widget.onRegisterAsset == null
              ? null
              : () => widget.onRegisterAsset!(context, ref),
          icon: const Icon(Icons.add),
          label: Text(strings.registerAsset),
        ),
      ],
      child: AssetsConfigurationAsyncView<PageResult<AssetSummary>>(
        value: page,
        onRetry: () => ref.invalidate(assetPageProvider(request)),
        data: (result) => AssetRegisterView(
          assets: result.items,
          searchQuery: _search,
          onSearchChanged: _searchChanged,
          onSelected: widget.onAssetSelected,
          onPreviousPage: _cursor == null
              ? null
              : () => setState(() {
                    _cursor = _previousCursor;
                    _previousCursor = null;
                  }),
          onNextPage: result.hasMore
              ? () => setState(() {
                    _previousCursor = _cursor;
                    _cursor = result.nextCursor;
                  })
              : null,
        ),
      ),
    );
  }
}
