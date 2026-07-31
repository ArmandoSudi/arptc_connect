import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_attachment_upload.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class TaskAttachmentField extends StatefulWidget {
  const TaskAttachmentField({
    super.key,
    required this.label,
    required this.onChanged,
    required this.onRemoveChanged,
    this.currentAttachment,
    this.selectedUpload,
    this.removed = false,
  });

  static const maxFileSizeBytes = 20 * 1024 * 1024;

  final String label;
  final TaskAttachment? currentAttachment;
  final TaskAttachmentUpload? selectedUpload;
  final bool removed;
  final ValueChanged<TaskAttachmentUpload?> onChanged;
  final ValueChanged<bool> onRemoveChanged;

  @override
  State<TaskAttachmentField> createState() => _TaskAttachmentFieldState();
}

class _TaskAttachmentFieldState extends State<TaskAttachmentField> {
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final selected = widget.selectedUpload;
    final current = widget.removed ? null : widget.currentAttachment;
    final hasFile = selected != null || current?.isAvailable == true;
    final fileName = selected?.fileName ??
        current?.fileName.trim().takeIfNotEmpty ??
        l10n.document;
    final fileSize = selected == null ? null : _formatBytes(selected.size);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (hasFile)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: fileSize == null ? null : Text(fileSize),
              trailing: IconButton(
                tooltip: l10n.remove,
                onPressed: () {
                  widget.onChanged(null);
                  widget.onRemoveChanged(true);
                },
                icon: const Icon(Icons.close),
              ),
            )
          else
            Text(
              l10n.noFileSelected,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isPicking ? null : _pickFile,
            icon: _isPicking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            label: Text(hasFile ? l10n.replaceFile : l10n.selectFile),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'webp',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
        ],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showError(S.of(context).fileCouldNotBeRead);
        return;
      }
      if (bytes.lengthInBytes > TaskAttachmentField.maxFileSizeBytes) {
        _showError(S.of(context).fileTooLarge);
        return;
      }

      widget.onChanged(TaskAttachmentUpload(
        bytes: bytes,
        fileName: file.name,
        contentType: taskAttachmentContentType(file.extension),
      ));
      widget.onRemoveChanged(false);
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

String taskAttachmentContentType(String? extension) {
  switch ((extension ?? '').trim().toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}

extension on String {
  String? get takeIfNotEmpty => trim().isEmpty ? null : trim();
}
