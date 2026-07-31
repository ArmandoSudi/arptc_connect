import 'dart:math';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/knowledge_editor_form.dart';
import '../widgets/knowledge_layout.dart';

class KnowledgeEditorScreen extends ConsumerStatefulWidget {
  const KnowledgeEditorScreen({
    super.key,
    this.article,
    this.version,
    this.filePicker,
    this.attachmentIdFactory,
  });

  final KnowledgeArticle? article;
  final KnowledgeArticleVersion? version;
  final KnowledgeFilePicker? filePicker;
  final String Function()? attachmentIdFactory;

  @override
  ConsumerState<KnowledgeEditorScreen> createState() =>
      _KnowledgeEditorScreenState();
}

class _KnowledgeEditorScreenState extends ConsumerState<KnowledgeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late String _categoryId;
  late String _languageCode;
  late KnowledgeVisibility _visibility;
  late bool _isFeatured;
  var _pendingAttachments = <KnowledgeDraftAttachment>[];
  var _newAttachmentsInternal = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.version?.title);
    _summaryController = TextEditingController(text: widget.version?.summary);
    _contentController = TextEditingController(text: widget.version?.content);
    _categoryId = widget.article?.categoryId ?? '';
    _languageCode = widget.version?.languageCode ?? 'en';
    _visibility = widget.article?.visibility ?? KnowledgeVisibility.employee;
    _isFeatured = widget.article?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final policy = ref.watch(knowledgeAccessPolicyProvider);
    final categoriesState = ref.watch(
      knowledgeCategoriesProvider(const KnowledgeCategoryRequest()),
    );
    final actionState = ref.watch(knowledgeActionProvider(_actionScope));
    if (policy.isLoading || categoriesState.isLoading) {
      return KnowledgePage(
        title: l10n.edit,
        onBack: () => Navigator.of(context).maybePop(),
        child: KnowledgeAsyncState(
          icon: Icons.hourglass_top_rounded,
          title: l10n.loading,
          isLoading: true,
        ),
      );
    }
    if (!(policy.valueOrNull?.canManage ?? false)) {
      return KnowledgePage(
        title: l10n.edit,
        onBack: () => Navigator.of(context).maybePop(),
        child: KnowledgeAsyncState(
          icon: Icons.lock_outline_rounded,
          title: l10n.itsmAccessDeniedTitle,
        ),
      );
    }
    if (categoriesState.hasError) {
      return KnowledgePage(
        title: l10n.edit,
        onBack: () => Navigator.of(context).maybePop(),
        child: KnowledgeAsyncState(
          icon: Icons.error_outline_rounded,
          title: l10n.unableToLoad,
          error: categoriesState.error,
          onRetry: () => ref.invalidate(
            knowledgeCategoriesProvider(const KnowledgeCategoryRequest()),
          ),
        ),
      );
    }
    final categories = categoriesState.valueOrNull ?? const [];
    if (_categoryId.isEmpty && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _categoryId.isEmpty) {
          setState(() => _categoryId = categories.first.id);
        }
      });
    }
    return KnowledgePage(
      title: widget.article == null ? l10n.create : l10n.edit,
      onBack: () => Navigator.of(context).maybePop(),
      child: KnowledgeEditorForm(
        formKey: _formKey,
        titleController: _titleController,
        summaryController: _summaryController,
        contentController: _contentController,
        categories: categories,
        categoryId: _categoryId,
        languageCode: _languageCode,
        visibility: _visibility,
        isFeatured: _isFeatured,
        existingAttachments: widget.version?.attachments ?? const [],
        pendingAttachments: _pendingAttachments,
        newAttachmentsInternal: _newAttachmentsInternal,
        isSaving: actionState.isLoading,
        onCategoryChanged: (value) {
          if (value != null) setState(() => _categoryId = value);
        },
        onLanguageChanged: (value) {
          if (value != null) setState(() => _languageCode = value);
        },
        onVisibilityChanged: (value) {
          if (value != null) setState(() => _visibility = value);
        },
        onFeaturedChanged: (value) => setState(() => _isFeatured = value),
        onNewAttachmentsInternalChanged: (value) =>
            setState(() => _newAttachmentsInternal = value),
        onPickAttachment: _pickAttachment,
        onRemovePendingAttachment: (attachmentId) => setState(() {
          _pendingAttachments = _pendingAttachments
              .where((item) => item.id != attachmentId)
              .toList(growable: false);
        }),
        onSave: _save,
      ),
    );
  }

  String get _actionScope => 'editor:${widget.article?.id ?? 'new'}';

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = S.of(context);
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final controller =
          await ref.read(knowledgeCommandControllerProvider.future);
      final input = KnowledgeDraftInput(
        categoryId: _categoryId,
        title: _titleController.text,
        summary: _summaryController.text,
        content: _contentController.text,
        languageCode: _languageCode,
        visibility: _visibility,
        isFeatured: _isFeatured,
        attachments: _pendingAttachments,
      );
      final command = SaveKnowledgeDraftCommand(
        context: _context(session),
        input: input,
        articleId: widget.article?.id ?? '',
        expectedState: widget.article?.state,
        expectedVersionNumber: widget.version?.versionNumber,
      );
      final receipt =
          await ref.read(knowledgeActionProvider(_actionScope).notifier).run(
                () => controller.saveDraft(
                  command: command,
                  article: widget.article,
                  version: widget.version,
                ),
              );
      if (mounted) Navigator.of(context).pop(receipt);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $error')),
        );
      }
    }
  }

  Future<void> _pickAttachment() async {
    final l10n = S.of(context);
    try {
      final file =
          await (widget.filePicker ?? const PlatformKnowledgeFilePicker())
              .pick();
      if (file == null || !mounted) return;
      final attachment = KnowledgeDraftAttachment(
        id: (widget.attachmentIdFactory ?? _newAttachmentId).call(),
        fileName: file.fileName,
        contentType: file.contentType,
        bytes: file.bytes,
        isInternal: _newAttachmentsInternal,
      );
      setState(() => _pendingAttachments = [
            ..._pendingAttachments,
            attachment,
          ]);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $error')),
        );
      }
    }
  }

  String _newAttachmentId() {
    final random = Random.secure().nextInt(0x7fffffff);
    return 'attachment_${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  ItsmCommandContext _context(ItsmSession session) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return ItsmCommandContext(
      idempotencyKey: 'knowledge-save-${session.userId}-$now',
      correlationId: 'knowledge-${widget.article?.id ?? 'new'}-$now',
      actorUserId: session.userId,
      actorDisplayName: session.displayName,
      actorRole: session.role,
    );
  }
}

class PlatformKnowledgeFilePicker implements KnowledgeFilePicker {
  const PlatformKnowledgeFilePicker();

  @override
  Future<KnowledgePickedFile?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const KnowledgeGatewayException(
        'The selected file could not be read.',
      );
    }
    final contentType = _contentTypeFor(file.name, file.extension);
    if (contentType == null) {
      throw const KnowledgeGatewayException(
        'The selected file type is not supported.',
      );
    }
    return KnowledgePickedFile(
      fileName: file.name,
      contentType: contentType,
      bytes: bytes,
    );
  }

  String? _contentTypeFor(String fileName, String? extension) {
    final normalized = (extension ?? fileName.split('.').last).toLowerCase();
    return switch (normalized) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'txt' => 'text/plain',
      'csv' => 'text/csv',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      _ => null,
    };
  }
}
