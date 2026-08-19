import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:flutter/material.dart';

import '../../application/service_request_form_controller.dart';
import '../../domain/service_catalogue.dart';

class ServiceRequestFormView extends StatelessWidget {
  const ServiceRequestFormView({
    required this.state,
    required this.languageCode,
    required this.canRequestOnBehalf,
    required this.agents,
    required this.agentSearchQuery,
    required this.onAgentSearchChanged,
    required this.onAgentSelected,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onResponseChanged,
    required this.onPickDocument,
    required this.onRemoveDocument,
    required this.onSubmit,
    super.key,
  });

  final ServiceRequestFormState state;
  final String languageCode;
  final bool canRequestOnBehalf;
  final List<AgentDirectoryEntry> agents;
  final String agentSearchQuery;
  final ValueChanged<String> onAgentSearchChanged;
  final ValueChanged<AgentDirectoryEntry> onAgentSelected;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final void Function(String key, Object? value) onResponseChanged;
  final ValueChanged<CatalogueRequiredDocument> onPickDocument;
  final ValueChanged<String> onRemoveDocument;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Form(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CorporateSurfaceCard(
            title: state.catalogueItem.name.resolve(languageCode),
            subtitle: state.catalogueItem.description.resolve(languageCode),
            accentColor: Theme.of(context).colorScheme.primary,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(state.catalogueItem.code)),
                Chip(
                  label: Text(
                    state.catalogueItem.categoryName.resolve(languageCode),
                  ),
                ),
              ],
            ),
          ),
          if (canRequestOnBehalf) ...[
            const SizedBox(height: 16),
            CorporateSurfaceCard(
              title: l10n.requestOnBehalfOf,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommonTextInput(
                    label: l10n.searchAgents,
                    hintText: l10n.searchByNameEmailOrMatricule,
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    onChanged: onAgentSearchChanged,
                  ),
                  if (agentSearchQuery.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...agents.take(6).map(
                          (agent) => ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(agent.displayName),
                            subtitle: Text(agent.email),
                            selected: agent.id == state.requestedFor.userId,
                            onTap: () => onAgentSelected(agent),
                          ),
                        ),
                  ],
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(
                        '${l10n.requestedFor}: ${state.requestedFor.name}'),
                    subtitle: Text(state.requestedFor.email),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          CorporateSurfaceCard(
            title: l10n.agentInformation,
            child: Column(
              children: [
                CommonTextInput(
                  label: l10n.title,
                  initialValue: state.title,
                  onChanged: onTitleChanged,
                  validator: (value) =>
                      value?.trim().isEmpty == true ? l10n.errorOccurred : null,
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  label: l10n.description,
                  initialValue: state.description,
                  isMultiline: true,
                  onChanged: onDescriptionChanged,
                ),
                for (final field in state.catalogueItem.formFields) ...[
                  const SizedBox(height: 16),
                  _DynamicField(
                    field: field,
                    languageCode: languageCode,
                    value: state.responses[field.key],
                    onChanged: (value) => onResponseChanged(field.key, value),
                  ),
                ],
              ],
            ),
          ),
          if (state.catalogueItem.requiredDocuments.isNotEmpty) ...[
            const SizedBox(height: 16),
            CorporateSurfaceCard(
              title: l10n.documents,
              child: Column(
                children: [
                  for (final requirement
                      in state.catalogueItem.requiredDocuments) ...[
                    ListTile(
                      leading: Icon(
                        requirement.required
                            ? Icons.description_outlined
                            : Icons.description,
                      ),
                      title: Text(requirement.label.resolve(languageCode)),
                      subtitle: requirement.description == null
                          ? null
                          : Text(
                              requirement.description!.resolve(languageCode),
                            ),
                      trailing: OutlinedButton.icon(
                        onPressed: state.isSubmitting ||
                                state.documents
                                        .where(
                                          (item) =>
                                              item.requirementId ==
                                              requirement.key,
                                        )
                                        .length >=
                                    requirement.maximumFiles
                            ? null
                            : () => onPickDocument(requirement),
                        icon: const Icon(Icons.attach_file),
                        label: Text(l10n.selectFile),
                      ),
                    ),
                    for (final document in state.documents.where(
                      (item) => item.requirementId == requirement.key,
                    ))
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 24),
                        leading: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(document.fileName),
                        subtitle: Text(
                          '${document.contentType} · ${_formatBytes(document.sizeBytes)}',
                        ),
                        trailing: IconButton(
                          tooltip: l10n.remove,
                          onPressed: state.isSubmitting
                              ? null
                              : () => onRemoveDocument(document.attachmentId),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: state.isSubmitting ? null : onSubmit,
            icon: state.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(state.isSubmitting ? l10n.submitting : l10n.submit),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
  }
}

class _DynamicField extends StatelessWidget {
  const _DynamicField({
    required this.field,
    required this.languageCode,
    required this.value,
    required this.onChanged,
  });

  final CatalogueFieldSchema field;
  final String languageCode;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = field.label.resolve(languageCode);
    final help = field.helpText?.resolve(languageCode);
    switch (field.type) {
      case CatalogueFieldType.boolean:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: help == null ? null : Text(help),
          value: value == true,
          onChanged: onChanged,
        );
      case CatalogueFieldType.singleSelect:
        return DropdownButtonFormField<String>(
          value: value?.toString(),
          decoration: InputDecoration(labelText: label, helperText: help),
          items: field.options
              .map(
                (option) => DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label.resolve(languageCode)),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        );
      case CatalogueFieldType.multiSelect:
        final selected = value is Iterable
            ? (value as Iterable).map((item) => item.toString()).toSet()
            : <String>{};
        return InputDecorator(
          decoration: InputDecoration(labelText: label, helperText: help),
          child: Wrap(
            spacing: 8,
            children: field.options.map((option) {
              return FilterChip(
                label: Text(option.label.resolve(languageCode)),
                selected: selected.contains(option.value),
                onSelected: (isSelected) {
                  final next = Set<String>.of(selected);
                  isSelected
                      ? next.add(option.value)
                      : next.remove(option.value);
                  onChanged(next.toList(growable: false));
                },
              );
            }).toList(growable: false),
          ),
        );
      case CatalogueFieldType.integer:
      case CatalogueFieldType.decimal:
        return CommonTextInput(
          label: label,
          hintText: help,
          initialValue: value?.toString(),
          type: field.type == CatalogueFieldType.integer
              ? CommonTextInputType.number
              : CommonTextInputType.decimal,
          onChanged: (text) => onChanged(
            field.type == CatalogueFieldType.integer
                ? int.tryParse(text)
                : double.tryParse(text.replaceAll(',', '.')),
          ),
        );
      case CatalogueFieldType.longText:
        return CommonTextInput(
          label: label,
          hintText: help,
          initialValue: value?.toString(),
          isMultiline: true,
          onChanged: onChanged,
        );
      case CatalogueFieldType.email:
        return CommonTextInput(
          label: label,
          hintText: help,
          initialValue: value?.toString(),
          type: CommonTextInputType.email,
          onChanged: onChanged,
        );
      case CatalogueFieldType.phone:
        return CommonTextInput(
          label: label,
          hintText: help,
          initialValue: value?.toString(),
          type: CommonTextInputType.phone,
          onChanged: onChanged,
        );
      case CatalogueFieldType.date:
      case CatalogueFieldType.dateTime:
      case CatalogueFieldType.user:
      case CatalogueFieldType.asset:
      case CatalogueFieldType.attachment:
      case CatalogueFieldType.shortText:
        return CommonTextInput(
          label: label,
          hintText: help,
          initialValue: value?.toString(),
          onChanged: onChanged,
        );
    }
  }
}
