import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reporting_administration_providers.dart';
import '../reporting_administration_strings.dart';

class ServiceCatalogueParametersScreen extends ConsumerWidget {
  const ServiceCatalogueParametersScreen({
    super.key,
    this.onOpenWorkflows,
    this.onOpenSlaPolicies,
    this.onOpenConfigurationItems,
  });

  final VoidCallback? onOpenWorkflows;
  final VoidCallback? onOpenSlaPolicies;
  final VoidCallback? onOpenConfigurationItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ReportingAdministrationStrings.of(context);
    final references = ref.watch(catalogueReferenceDataProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.value('catalogueParameters'))),
      body: references.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: strings.value('error'),
          description: error.toString(),
          onRetry: () => ref.invalidate(catalogueReferenceDataProvider),
        ),
        data: (values) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              strings.value('catalogueParametersDescription'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _ReferenceSection(
              title: strings.value('catalogueCategories'),
              type: 'catalogue_category',
              icon: Icons.category_outlined,
              values: values,
            ),
            const SizedBox(height: 16),
            _ReferenceSection(
              title: strings.value('fulfilmentGroups'),
              type: 'assignment_group',
              icon: Icons.groups_outlined,
              values: values,
            ),
            const SizedBox(height: 16),
            _ReferenceSection(
              title: strings.value('approvalPolicies'),
              type: 'approval_policy',
              icon: Icons.fact_check_outlined,
              values: values,
            ),
            const SizedBox(height: 24),
            Text(
              strings.value('catalogueLinkedConfiguration'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            _NavigationTile(
              icon: Icons.account_tree_outlined,
              title: strings.value('workflows'),
              subtitle: strings.value('manageWorkflowsFromCatalogue'),
              onTap: onOpenWorkflows,
            ),
            _NavigationTile(
              icon: Icons.timer_outlined,
              title: strings.value('sla'),
              subtitle: strings.value('manageSlaFromCatalogue'),
              onTap: onOpenSlaPolicies,
            ),
            _NavigationTile(
              icon: Icons.device_hub_outlined,
              title: strings.value('underlyingCis'),
              subtitle: strings.value('manageConfigurationItemsFromCatalogue'),
              onTap: onOpenConfigurationItems,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceSection extends ConsumerWidget {
  const _ReferenceSection({
    required this.title,
    required this.type,
    required this.icon,
    required this.values,
  });

  final String title;
  final String type;
  final IconData icon;
  final List<CatalogueReferenceData> values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ReportingAdministrationStrings.of(context);
    final filtered = values.where((value) => value.type == type).toList()
      ..sort((left, right) => left.label.compareTo(right.label));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: strings.value('addParameter'),
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _edit(context, ref),
                ),
              ],
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: EmptyStateView(
                  icon: icon,
                  title: strings.value('noParameters'),
                  description: strings.value('addParameterToUseInCatalogue'),
                ),
              )
            else
              ...filtered.map(
                (value) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(value.label),
                  subtitle: Text(value.id),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: strings.value('edit'),
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(context, ref, existing: value),
                      ),
                      IconButton(
                        tooltip: strings.value('deactivate'),
                        icon: const Icon(Icons.pause_circle_outline),
                        onPressed: () => _deactivate(context, ref, value),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    CatalogueReferenceData? existing,
  }) async {
    final value = await showDialog<_ReferenceDraft>(
      context: context,
      builder: (_) => _ReferenceDialog(title: title, initialValue: existing),
    );
    if (value == null || !context.mounted) return;
    try {
      final controller =
          await ref.read(catalogueParameterControllerProvider.future);
      await controller.save(
        id: value.id,
        type: type,
        label: value.label,
        idempotencyKey:
            'catalogue-parameter-$type-${value.id}-${DateTime.now().microsecondsSinceEpoch}',
      );
      ref.invalidate(catalogueReferenceDataProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    CatalogueReferenceData value,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(ReportingAdministrationStrings.of(context)
            .value('deactivateParameter')),
        content: Text(value.label),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
                ReportingAdministrationStrings.of(context).value('deactivate')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final controller =
          await ref.read(catalogueParameterControllerProvider.future);
      await controller.deactivate(
        id: value.id,
        idempotencyKey:
            'catalogue-parameter-deactivate-${value.id}-${DateTime.now().microsecondsSinceEpoch}',
      );
      ref.invalidate(catalogueReferenceDataProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class _ReferenceDraft {
  const _ReferenceDraft({required this.id, required this.label});
  final String id;
  final String label;
}

class _ReferenceDialog extends StatefulWidget {
  const _ReferenceDialog({required this.title, this.initialValue});
  final String title;
  final CatalogueReferenceData? initialValue;

  @override
  State<_ReferenceDialog> createState() => _ReferenceDialogState();
}

class _ReferenceDialogState extends State<_ReferenceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _id = TextEditingController(text: widget.initialValue?.id ?? '');
  late final _label =
      TextEditingController(text: widget.initialValue?.label ?? '');

  @override
  void dispose() {
    _id.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonTextInput(
                label: strings.value('parameterId'),
                controller: _id,
                readOnly: widget.initialValue != null,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CommonTextInput(
                label: strings.value('parameterLabel'),
                controller: _label,
                validator: _required,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.of(context).pop(
              _ReferenceDraft(id: _id.text.trim(), label: _label.text.trim()),
            );
          },
          child: Text(strings.value('saveDraft')),
        ),
      ],
    );
  }

  String? _required(String? value) =>
      value?.trim().isNotEmpty == true ? null : 'Required';
}
