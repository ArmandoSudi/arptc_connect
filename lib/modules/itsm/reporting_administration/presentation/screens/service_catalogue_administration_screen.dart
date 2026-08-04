import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/itsm_common.dart';
import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../data/catalogue_administration_repository.dart';
import '../../domain/catalogue_configuration.dart';
import '../reporting_administration_strings.dart';
import '../widgets/catalogue_item_form.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class ServiceCatalogueAdministrationScreen extends ConsumerStatefulWidget {
  const ServiceCatalogueAdministrationScreen(
      {super.key,
      this.onOpenItem,
      this.onCreateDraft,
      this.onManageParameters});
  final ValueChanged<String>? onOpenItem;
  final VoidCallback? onCreateDraft;
  final VoidCallback? onManageParameters;

  @override
  ConsumerState<ServiceCatalogueAdministrationScreen> createState() =>
      _ServiceCatalogueAdministrationScreenState();
}

class _ServiceCatalogueAdministrationScreenState
    extends ConsumerState<ServiceCatalogueAdministrationScreen> {
  late final request = CatalogueItemsPageRequest(
      query: const CatalogueAdministrationQuery(), page: PageRequest());
  var _isSaving = false;

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
        if (access?.canOperate == true && widget.onManageParameters != null)
          OutlinedButton.icon(
            onPressed: widget.onManageParameters,
            icon: const Icon(Icons.tune_outlined),
            label: Text(strings.value('catalogueParameters')),
          ),
        if (access?.canOperate == true)
          FilledButton.icon(
              onPressed:
                  _isSaving ? null : widget.onCreateDraft ?? _createDraft,
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

  Future<void> _createDraft() async {
    final value = await showModalBottomSheet<CatalogueItemDraftValue>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final parameters = ref.watch(catalogueFormParametersProvider);
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.92,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: parameters.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
                  data: (value) => SingleChildScrollView(
                    child: CatalogueItemForm(
                      parameters: value,
                      onSubmit: (draft) => Navigator.of(context).pop(draft),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (value == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final version = CatalogueItemVersionConfiguration(
        itemId: value.code,
        versionId: 'v1',
        version: 1,
        state: ItsmPublicationState.draft,
        name: {'en': value.nameEn, 'fr': value.nameFr},
        description: {'en': value.descriptionEn, 'fr': value.descriptionFr},
        categoryId: value.categoryId,
        workflowId: value.workflowId,
        workflowVersion: value.workflowVersion,
        slaPolicyId: value.slaPolicyId,
        slaPolicyVersion: value.slaPolicyVersion,
        visibleRoles: value.visibleRoles,
        fieldKeys: value.formFields
            .map((field) => field['key']?.toString() ?? '')
            .where((key) => key.isNotEmpty),
        requiredDocumentKeys: value.requiredDocuments
            .map((document) => document['key']?.toString() ?? '')
            .where((key) => key.isNotEmpty),
        fulfilmentGroupId: value.fulfilmentGroupId,
        createdAt: DateTime.now().toUtc(),
        createdBy: 'active-manager',
      );
      final controller =
          await ref.read(catalogueConfigurationControllerProvider.future);
      final result = await controller.saveDraft(
        version,
        payload: value.toPayload(),
        create: true,
        idempotencyKey:
            'catalogue-create-${value.code}-${DateTime.now().microsecondsSinceEpoch}',
      );
      ref.invalidate(catalogueItemsPageProvider(request));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ReportingAdministrationStrings.of(context)
                .value('draftCreated'))),
      );
      final itemId = result.entityId ?? value.code;
      widget.onOpenItem?.call(itemId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
