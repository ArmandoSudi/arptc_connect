import 'dart:math';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../application/service_request_form_controller.dart';
import '../../application/service_request_access_policy.dart';
import '../../application/support_providers.dart';
import '../../data/service_request_command_gateway.dart';
import '../../domain/service_catalogue.dart';
import '../widgets/service_request_form_view.dart';

class CreateServiceRequestScreen extends ConsumerStatefulWidget {
  const CreateServiceRequestScreen({
    required this.catalogueItemId,
    super.key,
    this.onSubmitted,
    this.initialDocuments = const [],
    this.initialResponses = const {},
    this.initialTitle = '',
    this.initialDescription = '',
    this.filePicker,
    this.attachmentIdFactory,
  });

  final String catalogueItemId;
  final ValueChanged<ServiceRequestSubmissionReceipt>? onSubmitted;
  final List<ServiceRequestSubmissionDocument> initialDocuments;
  final Map<String, Object?> initialResponses;
  final String initialTitle;
  final String initialDescription;
  final ServiceRequestFilePicker? filePicker;
  final String Function()? attachmentIdFactory;

  @override
  ConsumerState<CreateServiceRequestScreen> createState() =>
      _CreateServiceRequestScreenState();
}

class _CreateServiceRequestScreenState
    extends ConsumerState<CreateServiceRequestScreen> {
  late final DateTime _effectiveAt;
  ServiceRequestFormController? _form;
  ItsmCommandContext? _commandContext;
  var _agentSearch = '';
  Object? _submitError;

  @override
  void initState() {
    super.initState();
    _effectiveAt = DateTime.now().toUtc();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final sessionAsync = ref.watch(itsmSessionProvider);
    final session = sessionAsync.valueOrNull;
    final catalogueContext =
        ref.watch(serviceRequestCatalogueContextProvider).valueOrNull;
    final itemRequest = PublishedCatalogueItemRequest(
      id: widget.catalogueItemId,
      at: _effectiveAt,
      departmentId: catalogueContext?.departmentId,
      serviceId: catalogueContext?.serviceId,
    );
    final itemAsync =
        ref.watch(publishedServiceCatalogueItemProvider(itemRequest));
    final agents = session?.role == ItsmRole.manager
        ? ref
                .watch(
                  serviceRequestAgentSearchProvider(
                    ServiceRequestAgentSearch(_agentSearch),
                  ),
                )
                .valueOrNull ??
            const <UserManagementAgent>[]
        : const <UserManagementAgent>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itsmServiceRequests)),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () => ref
              .invalidate(publishedServiceCatalogueItemProvider(itemRequest)),
        ),
        data: (item) {
          if (item == null || session == null) {
            return ErrorStateView(title: l10n.itsmAccessDeniedTitle);
          }
          _form ??= _newForm(item, session);
          final form = _form!;
          return Column(
            children: [
              if (_submitError != null)
                MaterialBanner(
                  content: Text(_submitError.toString()),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _submitError = null),
                      child: Text(l10n.close),
                    ),
                  ],
                ),
              Expanded(
                child: ServiceRequestFormView(
                  state: form.state,
                  languageCode: Localizations.localeOf(context).languageCode,
                  canRequestOnBehalf: session.role == ItsmRole.manager &&
                      item.allowManagerRequestOnBehalf,
                  agents: agents,
                  agentSearchQuery: _agentSearch,
                  onAgentSearchChanged: (value) =>
                      setState(() => _agentSearch = value),
                  onAgentSelected: (agent) => setState(() {
                    form.setRequestedFor(_targetFromAgent(agent));
                    _agentSearch = agent.displayName;
                  }),
                  onTitleChanged: (value) => form.setTitle(value),
                  onDescriptionChanged: (value) => form.setDescription(value),
                  onResponseChanged: (key, value) =>
                      setState(() => form.setResponse(key, value)),
                  onPickDocument: (requirement) =>
                      _pickDocument(form, requirement),
                  onRemoveDocument: (attachmentId) => setState(
                    () => form.removeDocument(attachmentId),
                  ),
                  onSubmit: () => _submit(form, session, catalogueContext),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ServiceRequestFormController _newForm(
    ServiceCatalogueItem item,
    ItsmSession session,
  ) {
    return ServiceRequestFormController(
      ServiceRequestFormState(
        catalogueItem: item,
        requestedFor: ServiceRequestTargetUser(
          userId: session.userId,
          name: session.displayName,
          email: session.email,
        ),
        title: widget.initialTitle,
        description: widget.initialDescription,
        responses: widget.initialResponses,
        documents: widget.initialDocuments,
      ),
    );
  }

  ServiceRequestTargetUser _targetFromAgent(UserManagementAgent agent) {
    return ServiceRequestTargetUser(
      userId: agent.id,
      name: agent.displayName,
      email: agent.email,
      departmentId: agent.departmentId,
      serviceId: agent.serviceId,
    );
  }

  Future<void> _pickDocument(
    ServiceRequestFormController form,
    CatalogueRequiredDocument requirement,
  ) async {
    try {
      final file =
          await (widget.filePicker ?? const PlatformServiceRequestFilePicker())
              .pick();
      if (file == null || !mounted) return;
      setState(() {
        form.addDocument(
          requirement: requirement,
          file: file,
          attachmentId: (widget.attachmentIdFactory ?? _newAttachmentId).call(),
        );
        _submitError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _submitError = error);
    }
  }

  String _newAttachmentId() {
    final random = Random.secure().nextInt(0x7fffffff);
    return 'attachment_${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  Future<void> _submit(
    ServiceRequestFormController form,
    ItsmSession session,
    ServiceRequestCatalogueContext? catalogueContext,
  ) async {
    final now = DateTime.now().toUtc();
    final validation = form.state.validate(
      principal: CataloguePrincipal(
        userId: session.userId,
        role: session.role,
        departmentId: catalogueContext?.departmentId,
        serviceId: catalogueContext?.serviceId,
      ),
      at: now,
    );
    if (!validation.isValid) {
      setState(
        () => _submitError = S.of(context).serviceRequestValidationIssues(
              validation.issues.map((issue) => issue.key).join(', '),
            ),
      );
      return;
    }
    setState(() {
      form.state = form.state.copyWith(isSubmitting: true);
      _submitError = null;
    });
    try {
      final context = _commandContext ??= ItsmCommandContext(
        idempotencyKey:
            'request-${session.userId}-${now.microsecondsSinceEpoch}',
        correlationId: 'request-${now.microsecondsSinceEpoch}',
        actorUserId: session.userId,
        actorRole: session.role,
        actorDisplayName: session.displayName,
      );
      final command = form.buildCommand(context);
      final controller =
          await ref.read(serviceRequestControllerProvider.future);
      final receipt = await controller.create(
        command: command,
        at: now,
        departmentId: catalogueContext?.departmentId,
        serviceId: catalogueContext?.serviceId,
      );
      widget.onSubmitted?.call(receipt);
    } catch (error) {
      if (mounted) setState(() => _submitError = error);
    } finally {
      if (mounted) {
        setState(() => form.state = form.state.copyWith(isSubmitting: false));
      }
    }
  }
}

class PlatformServiceRequestFilePicker implements ServiceRequestFilePicker {
  const PlatformServiceRequestFilePicker();

  @override
  Future<ServiceRequestPickedFile?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const ServiceRequestValidationException(
        'The selected file could not be read.',
      );
    }
    return ServiceRequestPickedFile(
      fileName: file.name,
      contentType: _contentTypeFor(file.name, file.extension),
      bytes: bytes,
    );
  }

  String _contentTypeFor(String fileName, String? extension) {
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
      _ => 'application/octet-stream',
    };
  }
}
