import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../data/catalogue_administration_repository.dart';
import '../reporting_administration_strings.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class ServiceCatalogueAdministrationScreen extends ConsumerStatefulWidget {
  const ServiceCatalogueAdministrationScreen(
      {super.key, this.onOpenItem, this.onCreateDraft});
  final ValueChanged<String>? onOpenItem;
  final VoidCallback? onCreateDraft;

  @override
  ConsumerState<ServiceCatalogueAdministrationScreen> createState() =>
      _ServiceCatalogueAdministrationScreenState();
}

class _ServiceCatalogueAdministrationScreenState
    extends ConsumerState<ServiceCatalogueAdministrationScreen> {
  late final request = CatalogueItemsPageRequest(
      query: const CatalogueAdministrationQuery(), page: PageRequest());

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final access = ref.watch(reportingAdministrationAccessProvider).valueOrNull;
    final result = ref.watch(catalogueItemsPageProvider(request));
    final language = Localizations.localeOf(context).languageCode;
    return ReportingPageShell(
      title: strings.value('catalogue'),
      subtitle: strings.value('catalogueDescription'),
      actions: [
        if (access?.canOperate == true)
          FilledButton.icon(
              onPressed: widget.onCreateDraft,
              icon: const Icon(Icons.add),
              label: Text(strings.value('createDraft'))),
        if (access?.isReadOnly == true)
          Chip(label: Text(strings.value('readOnly'))),
      ],
      child: ReportingAsyncState(
        value: result,
        loadingLabel: strings.value('loading'),
        errorLabel: strings.value('error'),
        emptyLabel: strings.value('empty'),
        isEmpty: (page) => page.isEmpty,
        onRetry: () => ref.invalidate(catalogueItemsPageProvider(request)),
        data: (page) => ConfigurationList(
          children: page.items
              .map((item) => ListTile(
                    onTap: widget.onOpenItem == null
                        ? null
                        : () => widget.onOpenItem!(item.id),
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(item.label(language)),
                    subtitle: Text('${item.code} • v${item.latestVersion}'),
                    trailing: ConfigurationStatusBadge(item.status),
                  ))
              .toList(growable: false),
        ),
      ),
    );
  }
}
