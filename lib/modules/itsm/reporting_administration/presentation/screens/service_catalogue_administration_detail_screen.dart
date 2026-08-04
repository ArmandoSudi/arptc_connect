import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../domain/catalogue_configuration.dart';
import '../../domain/configuration_common.dart';
import '../reporting_administration_strings.dart';
import '../widgets/catalogue_item_form.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class ServiceCatalogueAdministrationDetailScreen
    extends ConsumerStatefulWidget {
  const ServiceCatalogueAdministrationDetailScreen(
      {required this.itemId, super.key, this.onEditVersion});
  final String itemId;
  final ValueChanged<String>? onEditVersion;

  @override
  ConsumerState<ServiceCatalogueAdministrationDetailScreen> createState() =>
      _ServiceCatalogueAdministrationDetailScreenState();
}

class _ServiceCatalogueAdministrationDetailScreenState
    extends ConsumerState<ServiceCatalogueAdministrationDetailScreen> {
  late final versionsRequest = ConfigurationVersionsPageRequest(
    parentId: widget.itemId,
    page: PageRequest(),
  );
  var _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final item = ref.watch(catalogueItemProvider(widget.itemId));
    final versions = ref.watch(catalogueItemVersionsProvider(versionsRequest));
    final access = ref.watch(reportingAdministrationAccessProvider).valueOrNull;
    final language = Localizations.localeOf(context).languageCode;
    return ReportingPageShell(
      title: item.valueOrNull?.label(language) ?? strings.value('catalogue'),
      subtitle: access?.isReadOnly == true
          ? strings.value('configurationReadOnly')
          : strings.value('immutable'),
      child: ReportingAsyncState(
        value: versions,
        loadingLabel: strings.value('loading'),
        errorLabel: strings.value('error'),
        emptyLabel: strings.value('empty'),
        isEmpty: (page) => page.isEmpty,
        data: (page) {
          final configuration = item.valueOrNull;
          final draft = _currentDraft(configuration, page.items);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (access?.canOperate == true)
                _CatalogueLifecycleActions(
                  isSubmitting: _isSubmitting,
                  canRetire: configuration?.status.value == 'published',
                  draft: draft,
                  onEdit: draft == null ? null : () => _editDraft(draft),
                  onValidate:
                      draft == null ? null : () => _validateDraft(draft),
                  onPublish: draft == null ? null : () => _publishDraft(draft),
                  onRetire: configuration == null
                      ? null
                      : () => _retire(configuration),
                ),
              if (access?.canOperate == true) const SizedBox(height: 16),
              VersionHistoryPanel(
                versions: page.items
                    .map((version) => ConfigurationVersionSummary(
                          id: version.versionId,
                          version: version.version,
                          state: version.state,
                          createdAt: version.createdAt,
                          createdBy: version.createdBy,
                          publishedAt: version.publishedAt,
                        ))
                    .toList(growable: false),
                onSelected:
                    access?.canOperate == true && widget.onEditVersion != null
                        ? (version) => widget.onEditVersion!(version.id)
                        : null,
              ),
            ],
          );
        },
      ),
    );
  }

  CatalogueItemVersionConfiguration? _currentDraft(
    CatalogueItemConfiguration? item,
    List<CatalogueItemVersionConfiguration> versions,
  ) {
    final draftId = item?.currentDraftVersionDocumentId;
    for (final version in versions) {
      if (version.versionId == draftId ||
          (draftId == null && version.state.value == 'draft')) {
        return version;
      }
    }
    return null;
  }

  Future<void> _editDraft(CatalogueItemVersionConfiguration version) async {
    final strings = ReportingAdministrationStrings.of(context);
    CatalogueItemDraftValue initialValue;
    try {
      initialValue = CatalogueItemDraftValue.fromDefinition(
        widget.itemId,
        version.definition,
      );
    } on Object catch (error) {
      _showError(error);
      return;
    }
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
                      initialValue: initialValue,
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
    await _runCommand(() async {
      final controller =
          await ref.read(catalogueConfigurationControllerProvider.future);
      await controller.saveDraft(
        version,
        payload: value.toPayload(),
        idempotencyKey:
            'catalogue-update-${widget.itemId}-${DateTime.now().microsecondsSinceEpoch}',
      );
      _invalidate();
      _showMessage(strings.value('draftSaved'));
    });
  }

  Future<void> _validateDraft(CatalogueItemVersionConfiguration version) {
    final strings = ReportingAdministrationStrings.of(context);
    return _runCommand(() async {
      final controller =
          await ref.read(catalogueConfigurationControllerProvider.future);
      final result = await controller.validate(
        version,
        idempotencyKey:
            'catalogue-validate-${widget.itemId}-${DateTime.now().microsecondsSinceEpoch}',
      );
      _invalidate();
      _showMessage(result.wasDuplicate
          ? strings.value('alreadyProcessed')
          : strings.value('validationRequested'));
    });
  }

  Future<void> _publishDraft(CatalogueItemVersionConfiguration version) {
    final strings = ReportingAdministrationStrings.of(context);
    return _runCommand(() async {
      final controller =
          await ref.read(catalogueConfigurationControllerProvider.future);
      await controller.publish(
        itemId: widget.itemId,
        versionId: version.versionId,
        expectedRevision: version.revision,
        idempotencyKey:
            'catalogue-publish-${widget.itemId}-${DateTime.now().microsecondsSinceEpoch}',
      );
      _invalidate();
      _showMessage(strings.value('cataloguePublished'));
    });
  }

  Future<void> _retire(CatalogueItemConfiguration item) async {
    final strings = ReportingAdministrationStrings.of(context);
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.value('retire')),
        content: CommonTextInput(
          controller: controller,
          label: strings.value('retirementReason'),
          isMultiline: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(strings.value('retire')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    await _runCommand(() async {
      final controller =
          await ref.read(catalogueConfigurationControllerProvider.future);
      await controller.retire(
        itemId: widget.itemId,
        expectedRevision: item.revision,
        reason: reason,
        idempotencyKey:
            'catalogue-retire-${widget.itemId}-${DateTime.now().microsecondsSinceEpoch}',
      );
      _invalidate();
      _showMessage(strings.value('catalogueRetired'));
    });
  }

  Future<void> _runCommand(Future<void> Function() action) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _invalidate() {
    ref.invalidate(catalogueItemProvider(widget.itemId));
    ref.invalidate(catalogueItemVersionsProvider(versionsRequest));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) => _showMessage(error.toString());
}

class _CatalogueLifecycleActions extends StatelessWidget {
  const _CatalogueLifecycleActions({
    required this.isSubmitting,
    required this.canRetire,
    required this.draft,
    required this.onEdit,
    required this.onValidate,
    required this.onPublish,
    required this.onRetire,
  });

  final bool isSubmitting;
  final bool canRetire;
  final CatalogueItemVersionConfiguration? draft;
  final VoidCallback? onEdit;
  final VoidCallback? onValidate;
  final VoidCallback? onPublish;
  final VoidCallback? onRetire;

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(strings.value('editDraft')),
        ),
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : onValidate,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(strings.value('validate')),
        ),
        FilledButton.icon(
          onPressed: isSubmitting ? null : onPublish,
          icon: const Icon(Icons.publish_outlined),
          label: Text(strings.value('publish')),
        ),
        if (canRetire)
          OutlinedButton.icon(
            onPressed: isSubmitting ? null : onRetire,
            icon: const Icon(Icons.archive_outlined),
            label: Text(strings.value('retire')),
          ),
      ],
    );
  }
}
