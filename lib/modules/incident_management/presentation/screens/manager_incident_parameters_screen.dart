import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_category.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_resolution_code.dart';
import 'package:arptc_connect/modules/incident_management/domain/it_service.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManagerIncidentParametersScreen extends ConsumerWidget {
  const ManagerIncidentParametersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(managedIncidentCategoriesProvider);
    final servicesAsync = ref.watch(managedItServicesProvider);
    final resolutionCodesAsync =
        ref.watch(managedIncidentResolutionCodesProvider);
    final roleAsync = ref.watch(currentUserIncidentRoleProvider);
    final l10n = S.of(context);

    return Scaffold(
      body: ContentView(
        maxWidth: 1000,
        child: roleAsync.when(
          data: (role) {
            if (role != IncidentRole.manager) {
              return ErrorStateView(
                title: l10n.permissionDenied,
                description: l10n.incidentParametersDescription,
              );
            }

            return DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: PageHeader(
                          title: l10n.incidentParameters,
                          description: l10n.incidentParametersDescription,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    tabs: [
                      Tab(text: l10n.services),
                      Tab(text: l10n.category),
                      Tab(text: l10n.resolutionCodes),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ItServicesTab(servicesAsync: servicesAsync),
                        _CategoriesTab(categoriesAsync: categoriesAsync),
                        _ResolutionCodesTab(
                          resolutionCodesAsync: resolutionCodesAsync,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => LoadingStateView(message: l10n.loadingIncidentAccess),
          error: (error, _) => ErrorStateView(
            title: l10n.unableToLoadIncidentAccess,
            description: error.toString(),
            onRetry: () => ref.invalidate(currentUserIncidentRoleProvider),
          ),
        ),
      ),
    );
  }
}

class _ItServicesTab extends ConsumerWidget {
  const _ItServicesTab({
    required this.servicesAsync,
  });

  final AsyncValue<List<ItService>> servicesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _showItServiceSheet(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addItService),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: servicesAsync.when(
            data: (services) {
              if (services.isEmpty) {
                return EmptyStateView(
                  icon: Icons.design_services_outlined,
                  title: l10n.noItems,
                );
              }
              return ListView.separated(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return ListTile(
                    leading: Icon(
                      service.isActive
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                    ),
                    title: Text(service.name),
                    subtitle: Text(
                      service.description.isEmpty
                          ? (service.isActive ? l10n.active : l10n.inactive)
                          : service.description,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showItServiceSheet(
                        context,
                        service: service,
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              );
            },
            loading: () => LoadingStateView(message: l10n.loading),
            error: (error, _) => ErrorStateView(
              title: l10n.unableToLoad,
              description: error.toString(),
              onRetry: () => ref.invalidate(managedItServicesProvider),
            ),
          ),
        ),
      ],
    );
  }

  void _showItServiceSheet(
    BuildContext context, {
    ItService? service,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ItServiceSheet(service: service),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab({
    required this.categoriesAsync,
  });

  final AsyncValue<List<IncidentCategory>> categoriesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _showCategorySheet(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addCategory),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return EmptyStateView(
                  icon: Icons.category_outlined,
                  title: l10n.noItems,
                );
              }
              return ListView.separated(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: Icon(
                      category.isActive
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                    ),
                    title: Text(category.name),
                    subtitle: Text(
                      category.subcategories.isEmpty
                          ? (category.isActive ? l10n.active : l10n.inactive)
                          : category.subcategories.join(', '),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _showCategorySheet(context, category: category),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              );
            },
            loading: () => LoadingStateView(message: l10n.loading),
            error: (error, _) => ErrorStateView(
              title: l10n.unableToLoad,
              description: error.toString(),
              onRetry: () => ref.invalidate(managedIncidentCategoriesProvider),
            ),
          ),
        ),
      ],
    );
  }

  void _showCategorySheet(
    BuildContext context, {
    IncidentCategory? category,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _CategorySheet(category: category),
    );
  }
}

class _ResolutionCodesTab extends ConsumerWidget {
  const _ResolutionCodesTab({
    required this.resolutionCodesAsync,
  });

  final AsyncValue<List<IncidentResolutionCode>> resolutionCodesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _showResolutionCodeSheet(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addResolutionCode),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: resolutionCodesAsync.when(
            data: (resolutionCodes) {
              if (resolutionCodes.isEmpty) {
                return EmptyStateView(
                  icon: Icons.fact_check_outlined,
                  title: l10n.noResolutionCodes,
                );
              }
              return ListView.separated(
                itemCount: resolutionCodes.length,
                itemBuilder: (context, index) {
                  final resolutionCode = resolutionCodes[index];
                  return ListTile(
                    leading: Icon(
                      resolutionCode.isActive
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                    ),
                    title: Text(
                      resolutionCode.labelForLanguageCode(languageCode),
                    ),
                    subtitle: Text(
                      '${resolutionCode.code} • '
                      '${resolutionCode.isActive ? l10n.active : l10n.inactive}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showResolutionCodeSheet(
                        context,
                        resolutionCode: resolutionCode,
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
              );
            },
            loading: () => LoadingStateView(message: l10n.loading),
            error: (error, _) => ErrorStateView(
              title: l10n.unableToLoad,
              description: error.toString(),
              onRetry: () =>
                  ref.invalidate(managedIncidentResolutionCodesProvider),
            ),
          ),
        ),
      ],
    );
  }

  void _showResolutionCodeSheet(
    BuildContext context, {
    IncidentResolutionCode? resolutionCode,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ResolutionCodeSheet(resolutionCode: resolutionCode),
    );
  }
}

class _ResolutionCodeSheet extends ConsumerStatefulWidget {
  const _ResolutionCodeSheet({
    this.resolutionCode,
  });

  final IncidentResolutionCode? resolutionCode;

  @override
  ConsumerState<_ResolutionCodeSheet> createState() =>
      _ResolutionCodeSheetState();
}

class _ResolutionCodeSheetState extends ConsumerState<_ResolutionCodeSheet> {
  late final TextEditingController _codeController;
  late final TextEditingController _labelEnController;
  late final TextEditingController _labelFrController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeController =
        TextEditingController(text: widget.resolutionCode?.code ?? '');
    _labelEnController =
        TextEditingController(text: widget.resolutionCode?.labelEn ?? '');
    _labelFrController =
        TextEditingController(text: widget.resolutionCode?.labelFr ?? '');
    _isActive = widget.resolutionCode?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _labelEnController.dispose();
    _labelFrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return _ParameterSheetFrame(
      title: widget.resolutionCode == null
          ? l10n.addResolutionCode
          : l10n.editResolutionCode,
      isSaving: _isSaving,
      onSave: _save,
      children: [
        CommonTextInput(
          label: l10n.resolutionCodeIdentifier,
          hintText: l10n.resolutionCodeIdentifierHint,
          type: CommonTextInputType.text,
          controller: _codeController,
          enabled: widget.resolutionCode == null,
        ),
        const SizedBox(height: 12),
        CommonTextInput(
          label: l10n.resolutionCodeLabelEnglish,
          type: CommonTextInputType.name,
          controller: _labelEnController,
        ),
        const SizedBox(height: 12),
        CommonTextInput(
          label: l10n.resolutionCodeLabelFrench,
          type: CommonTextInputType.name,
          controller: _labelFrController,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          title: Text(l10n.active),
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final code = IncidentResolutionCode.normalizeCode(_codeController.text);
    final labelEn = _labelEnController.text.trim();
    final labelFr = _labelFrController.text.trim();
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (code.isEmpty || labelEn.isEmpty || labelFr.isEmpty || actor == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(incidentRepositoryProvider).saveResolutionCode(
            IncidentResolutionCode(
              id: widget.resolutionCode?.id ?? '',
              code: code,
              labelEn: labelEn,
              labelFr: labelFr,
              isActive: _isActive,
              createdAt: widget.resolutionCode?.createdAt,
              updatedAt: DateTime.now(),
            ),
            actor,
          );
      ref.invalidate(managedIncidentResolutionCodesProvider);
      ref.invalidate(incidentResolutionCodesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ItServiceSheet extends ConsumerStatefulWidget {
  const _ItServiceSheet({
    this.service,
  });

  final ItService? service;

  @override
  ConsumerState<_ItServiceSheet> createState() => _ItServiceSheetState();
}

class _ItServiceSheetState extends ConsumerState<_ItServiceSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.service?.description ?? '');
    _isActive = widget.service?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return _ParameterSheetFrame(
      title: widget.service == null ? l10n.addItService : l10n.edit,
      isSaving: _isSaving,
      onSave: _save,
      children: [
        CommonTextInput(
          label: l10n.name,
          type: CommonTextInputType.name,
          controller: _nameController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        CommonTextInput(
          label: l10n.description,
          type: CommonTextInputType.text,
          isMultiline: true,
          controller: _descriptionController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 3,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          title: Text(l10n.active),
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(incidentRepositoryProvider).saveItService(
            ItService(
              id: widget.service?.id ?? '',
              name: name,
              nameLower: name.toLowerCase(),
              description: _descriptionController.text.trim(),
              isActive: _isActive,
              createdAt: widget.service?.createdAt,
              updatedAt: DateTime.now(),
            ),
            actor,
          );
      ref.invalidate(managedItServicesProvider);
      ref.invalidate(itServicesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({
    this.category,
  });

  final IncidentCategory? category;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _subcategoriesController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _subcategoriesController = TextEditingController(
      text: widget.category?.subcategories.join(', ') ?? '',
    );
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return _ParameterSheetFrame(
      title: widget.category == null ? l10n.addCategory : l10n.edit,
      isSaving: _isSaving,
      onSave: _save,
      children: [
        CommonTextInput(
          label: l10n.name,
          type: CommonTextInputType.name,
          controller: _nameController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        CommonTextInput(
          label: l10n.subcategory,
          type: CommonTextInputType.text,
          isMultiline: true,
          controller: _subcategoriesController,
          decoration: InputDecoration(
            hintText: l10n.subcategory,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          title: Text(l10n.active),
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null) {
      return;
    }
    final subcategories = _subcategoriesController.text
        .split(',')
        .map((subcategory) => subcategory.trim())
        .where((subcategory) => subcategory.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);
    try {
      await ref.read(incidentRepositoryProvider).saveCategory(
            IncidentCategory(
              id: widget.category?.id ?? '',
              name: name,
              nameLower: name.toLowerCase(),
              subcategories: subcategories,
              isActive: _isActive,
              createdAt: widget.category?.createdAt,
              updatedAt: DateTime.now(),
            ),
            actor,
          );
      ref.invalidate(managedIncidentCategoriesProvider);
      ref.invalidate(incidentCategoriesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ParameterSheetFrame extends StatelessWidget {
  const _ParameterSheetFrame({
    required this.title,
    required this.children,
    required this.isSaving,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isSaving ? null : onSave,
                    child: Text(isSaving ? l10n.saving : l10n.save),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed:
                        isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
