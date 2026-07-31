import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

import 'knowledge_layout.dart';

class KnowledgeEditorForm extends StatelessWidget {
  const KnowledgeEditorForm({
    required this.formKey,
    required this.titleController,
    required this.summaryController,
    required this.contentController,
    required this.categories,
    required this.categoryId,
    required this.languageCode,
    required this.visibility,
    required this.isFeatured,
    required this.onCategoryChanged,
    required this.onLanguageChanged,
    required this.onVisibilityChanged,
    required this.onFeaturedChanged,
    required this.onSave,
    super.key,
    this.isSaving = false,
    this.existingAttachments = const [],
    this.pendingAttachments = const [],
    this.newAttachmentsInternal = false,
    this.onNewAttachmentsInternalChanged,
    this.onPickAttachment,
    this.onRemovePendingAttachment,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController contentController;
  final List<KnowledgeCategory> categories;
  final String categoryId;
  final String languageCode;
  final KnowledgeVisibility visibility;
  final bool isFeatured;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<KnowledgeVisibility?> onVisibilityChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final VoidCallback onSave;
  final bool isSaving;
  final List<KnowledgeAttachment> existingAttachments;
  final List<KnowledgeDraftAttachment> pendingAttachments;
  final bool newAttachmentsInternal;
  final ValueChanged<bool>? onNewAttachmentsInternalChanged;
  final VoidCallback? onPickAttachment;
  final ValueChanged<String>? onRemovePendingAttachment;

  KnowledgeDraftInput draftInput() => KnowledgeDraftInput(
        categoryId: categoryId,
        title: titleController.text,
        summary: summaryController.text,
        content: contentController.text,
        languageCode: languageCode,
        visibility: visibility,
        isFeatured: isFeatured,
        attachments: pendingAttachments,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Form(
      key: formKey,
      child: KnowledgePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CommonTextInput(
              label: l10n.title,
              controller: titleController,
              validator: _required(l10n),
            ),
            const SizedBox(height: 16),
            CommonTextInput(
              label: l10n.description,
              controller: summaryController,
              isMultiline: true,
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CommonTextInput(
              label: l10n.article,
              controller: contentController,
              isMultiline: true,
              minLines: 8,
              maxLines: 16,
              validator: _required(l10n),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final fields = [
                  DropdownButtonFormField<String>(
                    value: categoryId.isEmpty ? null : categoryId,
                    decoration: InputDecoration(labelText: l10n.category),
                    validator: (value) =>
                        value == null || value.isEmpty ? l10n.error : null,
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.localizedName(locale)),
                        ),
                    ],
                    onChanged: onCategoryChanged,
                  ),
                  DropdownButtonFormField<String>(
                    value: languageCode,
                    decoration: InputDecoration(labelText: l10n.language),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                      DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
                    ],
                    onChanged: onLanguageChanged,
                  ),
                  DropdownButtonFormField<KnowledgeVisibility>(
                    value: visibility,
                    decoration: InputDecoration(labelText: l10n.permissions),
                    items: [
                      DropdownMenuItem(
                        value: KnowledgeVisibility.employee,
                        child: Text(l10n.user),
                      ),
                      DropdownMenuItem(
                        value: KnowledgeVisibility.dsiOnly,
                        child: Text(l10n.manager),
                      ),
                    ],
                    onChanged: onVisibilityChanged,
                  ),
                ];
                if (constraints.maxWidth < 760) {
                  return Column(
                    children: [
                      for (var index = 0; index < fields.length; index++) ...[
                        fields[index],
                        if (index < fields.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var index = 0; index < fields.length; index++) ...[
                      Expanded(child: fields[index]),
                      if (index < fields.length - 1) const SizedBox(width: 14),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: isFeatured,
              title: Text(l10n.active),
              onChanged: isSaving ? null : onFeaturedChanged,
            ),
            const SizedBox(height: 12),
            _KnowledgeAttachmentsEditor(
              existingAttachments: existingAttachments,
              pendingAttachments: pendingAttachments,
              newAttachmentsInternal: newAttachmentsInternal,
              isSaving: isSaving,
              onInternalChanged: onNewAttachmentsInternalChanged,
              onPick: onPickAttachment,
              onRemove: onRemovePendingAttachment,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? l10n.saving : l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _required(S l10n) {
    return (value) => value == null || value.trim().isEmpty ? l10n.error : null;
  }
}

class _KnowledgeAttachmentsEditor extends StatelessWidget {
  const _KnowledgeAttachmentsEditor({
    required this.existingAttachments,
    required this.pendingAttachments,
    required this.newAttachmentsInternal,
    required this.isSaving,
    required this.onInternalChanged,
    required this.onPick,
    required this.onRemove,
  });

  final List<KnowledgeAttachment> existingAttachments;
  final List<KnowledgeDraftAttachment> pendingAttachments;
  final bool newAttachmentsInternal;
  final bool isSaving;
  final ValueChanged<bool>? onInternalChanged;
  final VoidCallback? onPick;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.knowledgeAttachments,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.knowledgeAttachmentsHint),
            for (final attachment in existingAttachments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(attachment.fileName),
                subtitle: Text(_formatBytes(attachment.sizeBytes)),
                trailing: const Icon(Icons.lock_outline_rounded, size: 18),
              ),
            for (final attachment in pendingAttachments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  attachment.isInternal
                      ? Icons.lock_outline_rounded
                      : Icons.attach_file_rounded,
                ),
                title: Text(attachment.fileName),
                subtitle: Text(
                  '${attachment.contentType} · '
                  '${_formatBytes(attachment.sizeBytes)}',
                ),
                trailing: IconButton(
                  tooltip: l10n.remove,
                  onPressed: isSaving || onRemove == null
                      ? null
                      : () => onRemove!(attachment.id),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.internalAttachment),
              value: newAttachmentsInternal,
              onChanged: isSaving ? null : onInternalChanged,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onPick,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(l10n.selectFile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
  }
}
