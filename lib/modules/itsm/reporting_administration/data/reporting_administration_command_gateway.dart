import 'dart:collection';

enum ReportingAdministrationCommandType {
  createSlaDraft('itsmCreateSlaPolicyDraft'),
  updateSlaDraft('itsmUpdateSlaPolicyDraft'),
  validateSlaDraft('itsmValidateSlaPolicyDraft'),
  publishSlaVersion('itsmPublishSlaPolicyVersion'),
  retireSlaVersion('itsmRetireSlaPolicyVersion'),
  createCatalogueDraft('itsmCreateCatalogueItemDraft'),
  updateCatalogueDraft('itsmUpdateCatalogueItemDraft'),
  validateCatalogueDraft('itsmValidateCatalogueItemDraft'),
  publishCatalogueVersion('itsmPublishCatalogueItemVersion'),
  retireCatalogueVersion('itsmRetireCatalogueItemVersion'),
  createWorkflowDraft('itsmCreateWorkflowDraft'),
  updateWorkflowDraft('itsmUpdateWorkflowDraft'),
  validateWorkflowDraft('itsmValidateWorkflowDraft'),
  publishWorkflowVersion('itsmPublishWorkflowVersion'),
  retireWorkflowVersion('itsmRetireWorkflowVersion'),
  saveReferenceData('itsmSaveReferenceData'),
  deactivateReferenceData('itsmDeactivateReferenceData'),
  requestAuditExport('itsmRequestAuditExport');

  const ReportingAdministrationCommandType(this.functionName);
  final String functionName;
}

class ReportingAdministrationCommand {
  ReportingAdministrationCommand({
    required this.type,
    required this.idempotencyKey,
    required Map<String, Object?> payload,
  }) : payload = UnmodifiableMapView(Map<String, Object?>.from(payload)) {
    if (idempotencyKey.trim().isEmpty) {
      throw ArgumentError('An idempotency key is required.');
    }
  }

  final ReportingAdministrationCommandType type;
  final String idempotencyKey;
  final Map<String, Object?> payload;
}

class ReportingAdministrationCommandResult {
  const ReportingAdministrationCommandResult({
    required this.commandId,
    required this.acceptedAt,
    required this.wasDuplicate,
    this.entityId,
    this.versionId,
  });

  final String commandId;
  final String? entityId;
  final String? versionId;
  final DateTime acceptedAt;
  final bool wasDuplicate;
}

abstract interface class ReportingAdministrationCommandGateway {
  Future<ReportingAdministrationCommandResult> execute(
    ReportingAdministrationCommand command,
  );
}
