import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/support_providers.dart';
import '../../data/service_catalogue_repository.dart';
import '../../domain/service_catalogue.dart';
import '../../../shared/application/itsm_providers.dart';
import '../../../shared/domain/itsm_common.dart';
import '../widgets/service_catalogue_view.dart';

class ServiceCatalogueScreen extends ConsumerStatefulWidget {
  const ServiceCatalogueScreen({
    super.key,
    this.onItemSelected,
    this.onManageCatalogue,
  });

  final ValueChanged<ServiceCatalogueItem>? onItemSelected;
  final VoidCallback? onManageCatalogue;

  @override
  ConsumerState<ServiceCatalogueScreen> createState() =>
      _ServiceCatalogueScreenState();
}

class _ServiceCatalogueScreenState
    extends ConsumerState<ServiceCatalogueScreen> {
  var _search = '';
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final session = ref.watch(itsmSessionProvider).valueOrNull;
    final catalogueContext =
        ref.watch(serviceRequestCatalogueContextProvider).valueOrNull;
    final request = PublishedCatalogueFirstPageRequest(
      // Keep the first catalogue page bounded but broad enough for the local
      // category chips to reflect every service the signed-in user can request.
      query: ServiceCatalogueQuery(searchTerm: _search),
      limit: 100,
      languageCode: locale,
      departmentId: catalogueContext?.departmentId,
      serviceId: catalogueContext?.serviceId,
      locationId: catalogueContext?.locationId,
      positionValue: catalogueContext?.positionValue,
    );
    final items =
        ref.watch(publishedServiceCatalogueFirstPageProvider(request));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serviceCatalogueTitle),
        actions: [
          if (session?.role == ItsmRole.manager &&
              widget.onManageCatalogue != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: TextButton.icon(
                onPressed: widget.onManageCatalogue,
                icon: const Icon(Icons.settings_outlined),
                label: Text(l10n.manageServiceCatalogue),
              ),
            ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () => ref.invalidate(
            publishedServiceCatalogueFirstPageProvider(request),
          ),
        ),
        data: (values) => ServiceCatalogueView(
          items: values,
          languageCode: locale,
          searchQuery: _search,
          selectedCategoryId: _categoryId,
          onSearchChanged: (value) => setState(() => _search = value),
          onCategorySelected: (value) => setState(() => _categoryId = value),
          onItemSelected: widget.onItemSelected ?? (_) {},
        ),
      ),
    );
  }
}
