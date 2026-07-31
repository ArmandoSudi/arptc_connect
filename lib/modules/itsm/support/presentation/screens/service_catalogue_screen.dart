import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/support_providers.dart';
import '../../data/service_catalogue_repository.dart';
import '../../domain/service_catalogue.dart';
import '../widgets/service_catalogue_view.dart';

class ServiceCatalogueScreen extends ConsumerStatefulWidget {
  const ServiceCatalogueScreen({super.key, this.onItemSelected});

  final ValueChanged<ServiceCatalogueItem>? onItemSelected;

  @override
  ConsumerState<ServiceCatalogueScreen> createState() =>
      _ServiceCatalogueScreenState();
}

class _ServiceCatalogueScreenState
    extends ConsumerState<ServiceCatalogueScreen> {
  var _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final catalogueContext =
        ref.watch(serviceRequestCatalogueContextProvider).valueOrNull;
    final request = PublishedCatalogueFirstPageRequest(
      query: ServiceCatalogueQuery(searchTerm: _search),
      languageCode: locale,
      departmentId: catalogueContext?.departmentId,
      serviceId: catalogueContext?.serviceId,
    );
    final items =
        ref.watch(publishedServiceCatalogueFirstPageProvider(request));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itsmServiceCatalogue)),
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
          onSearchChanged: (value) => setState(() => _search = value),
          onItemSelected: widget.onItemSelected ?? (_) {},
        ),
      ),
    );
  }
}
