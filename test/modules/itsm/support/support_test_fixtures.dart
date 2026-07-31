import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/support/domain/support_domain.dart';

final fixtureTime = DateTime.utc(2026, 7, 31, 10);

ItsmSession fixtureSession(
  ItsmRole role, {
  String userId = 'user-1',
  String email = 'user@example.com',
}) {
  return ItsmSession(
    sessionKey: '$userId|$email',
    userId: userId,
    email: email,
    displayName: 'Test User',
    role: role,
  );
}

ServiceCatalogueItem fixtureCatalogueItem({
  String id = 'technical_assistance',
  ItsmPublicationState status = ItsmPublicationState.published,
  bool allowOnBehalf = true,
  bool allowsCancellation = true,
  Iterable<ItsmRole> visibleRoles = ItsmRole.values,
  CatalogueEligibility? eligibility,
  Iterable<CatalogueFieldSchema>? fields,
  Iterable<CatalogueRequiredDocument> documents = const [],
}) {
  return ServiceCatalogueItem(
    id: id,
    code: id,
    version: 2,
    name: LocalizedValue(
      en: 'Technical assistance',
      fr: 'Assistance technique',
    ),
    description: LocalizedValue(
      en: 'Request technical help.',
      fr: 'Demander une aide technique.',
    ),
    categoryId: 'support',
    categoryName: LocalizedValue(en: 'Support', fr: 'Assistance'),
    iconKey: 'support_agent',
    eligibility: eligibility ?? CatalogueEligibility(),
    visibleRoles: visibleRoles,
    workflow: VersionedConfigurationReference(
      id: 'standard-request',
      version: 3,
    ),
    approvalPolicyId: 'line-manager',
    fulfilmentGroupId: 'service-desk',
    slaPolicy: VersionedConfigurationReference(
      id: 'request-standard',
      version: 4,
    ),
    status: status,
    allowManagerRequestOnBehalf: allowOnBehalf,
    workflowAllowsCancellation: allowsCancellation,
    sortOrder: 20,
    formFields: fields ??
        [
          CatalogueFieldSchema(
            key: 'title',
            type: CatalogueFieldType.shortText,
            label: LocalizedValue(en: 'Title', fr: 'Titre'),
            required: true,
            minimumLength: 3,
            maximumLength: 100,
          ),
        ],
    requiredDocuments: documents,
    createdAt: fixtureTime,
    createdBy: 'manager-1',
    updatedAt: fixtureTime,
    updatedBy: 'manager-1',
  );
}

ServiceRequest fixtureRequest({
  String id = 'request-1',
  String requestedForUserId = 'user-1',
  String requesterId = 'user-1',
  ServiceRequestStatus status = ServiceRequestStatus.submitted,
  bool workflowAllowsCancellation = true,
  int workflowRevision = 0,
  String? rejectionReason,
  String? cancellationReason,
  bool selfServiceVisible = true,
  ItsmConfidentiality confidentiality = ItsmConfidentiality.internal,
}) {
  final lifecycle = switch (status) {
    ServiceRequestStatus.closed => ItsmLifecycleState.closed,
    ServiceRequestStatus.cancelled ||
    ServiceRequestStatus.rejected =>
      ItsmLifecycleState.cancelled,
    _ => ItsmLifecycleState.active,
  };
  return ServiceRequest(
    id: id,
    requestNumber: 'REQ-2026-0001',
    catalogueItemId: 'technical_assistance',
    catalogueItemCode: 'technical_assistance',
    catalogueItemVersion: 2,
    catalogueItemName: 'Technical assistance',
    title: 'Unable to connect',
    description: 'The application is unavailable.',
    requesterId: requesterId,
    requesterName: 'Requester',
    requesterEmail: 'requester@example.com',
    requestedForUserId: requestedForUserId,
    requestedForName: 'Affected User',
    requestedForEmail: 'user@example.com',
    departmentId: 'department-1',
    departmentName: 'Operations',
    serviceId: 'service-1',
    serviceName: 'Finance',
    responses: const {'title': 'Unable to connect'},
    workflowDefinitionId: 'standard-request',
    workflowVersion: 3,
    workflowInstanceId: 'workflow-instance-1',
    workflowRevision: workflowRevision,
    approvalPolicyId: 'line-manager',
    fulfilmentGroupId: 'service-desk',
    assignedGroupId: 'service-desk',
    slaPolicyId: 'request-standard',
    slaPolicyVersion: 4,
    status: status,
    lifecycleState: lifecycle,
    workflowAllowsCancellation: workflowAllowsCancellation,
    rejectionReason: rejectionReason,
    cancellationReason: cancellationReason,
    selfServiceVisible: selfServiceVisible,
    confidentiality: confidentiality,
    createdAt: fixtureTime,
    createdBy: requesterId,
    updatedAt: fixtureTime,
    updatedBy: requesterId,
  );
}
