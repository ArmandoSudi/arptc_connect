import '../../shared/domain/itsm_common.dart';
import 'service_catalogue.dart';
import 'service_request.dart';
import 'support_serialization.dart';

enum CatalogueSubmissionIssueCode {
  unavailableItem,
  unknownField,
  missingRequiredField,
  invalidFieldType,
  tooShort,
  tooLong,
  belowMinimum,
  aboveMaximum,
  invalidPattern,
  invalidOption,
  missingRequiredDocument,
  tooManyDocuments,
  unsupportedDocumentType,
}

class CatalogueSubmissionIssue {
  const CatalogueSubmissionIssue({
    required this.code,
    required this.key,
  });

  final CatalogueSubmissionIssueCode code;
  final String key;
}

class CatalogueSubmissionValidation {
  CatalogueSubmissionValidation(Iterable<CatalogueSubmissionIssue> issues)
      : issues = List<CatalogueSubmissionIssue>.unmodifiable(issues);

  final List<CatalogueSubmissionIssue> issues;

  bool get isValid => issues.isEmpty;
}

class SubmittedDocument {
  SubmittedDocument({
    required this.requirementKey,
    required this.contentType,
  }) {
    supportRequire(requirementKey, 'requirementKey');
    supportRequire(contentType, 'contentType');
  }

  final String requirementKey;
  final String contentType;
}

abstract final class CatalogueSubmissionValidator {
  static CatalogueSubmissionValidation validate({
    required ServiceCatalogueItem item,
    required CataloguePrincipal principal,
    required DateTime at,
    required Map<String, Object?> responses,
    Iterable<SubmittedDocument> documents = const [],
  }) {
    final issues = <CatalogueSubmissionIssue>[];
    if (!item.isAvailableTo(principal, at: at)) {
      issues.add(
        const CatalogueSubmissionIssue(
          code: CatalogueSubmissionIssueCode.unavailableItem,
          key: 'catalogueItem',
        ),
      );
      return CatalogueSubmissionValidation(issues);
    }

    final fieldsByKey = {
      for (final field in item.formFields) field.key: field,
    };
    for (final responseKey in responses.keys) {
      if (!fieldsByKey.containsKey(responseKey)) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.unknownField,
            key: responseKey,
          ),
        );
      }
    }

    for (final field in item.formFields) {
      if (!_isDependencyMet(field, responses)) continue;
      final value = responses[field.key];
      if (_isEmpty(value)) {
        if (field.required) {
          issues.add(
            CatalogueSubmissionIssue(
              code: CatalogueSubmissionIssueCode.missingRequiredField,
              key: field.key,
            ),
          );
        }
        continue;
      }
      _validateField(field, value!, issues);
    }

    final documentsByRequirement = <String, List<SubmittedDocument>>{};
    for (final document in documents) {
      documentsByRequirement
          .putIfAbsent(document.requirementKey, () => [])
          .add(document);
    }
    for (final requirement in item.requiredDocuments) {
      final submitted = documentsByRequirement[requirement.key] ??
          const <SubmittedDocument>[];
      if (requirement.required && submitted.isEmpty) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.missingRequiredDocument,
            key: requirement.key,
          ),
        );
      }
      if (submitted.length > requirement.maximumFiles) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.tooManyDocuments,
            key: requirement.key,
          ),
        );
      }
      if (requirement.allowedContentTypes.isNotEmpty &&
          submitted.any(
            (document) => !requirement.allowedContentTypes
                .contains(document.contentType.trim().toLowerCase()),
          )) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.unsupportedDocumentType,
            key: requirement.key,
          ),
        );
      }
    }
    return CatalogueSubmissionValidation(issues);
  }

  static void _validateField(
    CatalogueFieldSchema field,
    Object value,
    List<CatalogueSubmissionIssue> issues,
  ) {
    final validType = switch (field.type) {
      CatalogueFieldType.integer => value is int,
      CatalogueFieldType.decimal => value is num,
      CatalogueFieldType.boolean => value is bool,
      CatalogueFieldType.multiSelect => value is Iterable,
      CatalogueFieldType.date ||
      CatalogueFieldType.dateTime =>
        supportDateFromValue(value) != null,
      _ => value is String,
    };
    if (!validType) {
      issues.add(
        CatalogueSubmissionIssue(
          code: CatalogueSubmissionIssueCode.invalidFieldType,
          key: field.key,
        ),
      );
      return;
    }

    if (value is String) {
      if (field.minimumLength != null &&
          value.trim().length < field.minimumLength!) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.tooShort,
            key: field.key,
          ),
        );
      }
      if (field.maximumLength != null &&
          value.trim().length > field.maximumLength!) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.tooLong,
            key: field.key,
          ),
        );
      }
      final pattern = field.validationPattern;
      if (pattern != null && !RegExp(pattern).hasMatch(value)) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.invalidPattern,
            key: field.key,
          ),
        );
      }
    }
    if (value is num) {
      if (field.minimumValue != null && value < field.minimumValue!) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.belowMinimum,
            key: field.key,
          ),
        );
      }
      if (field.maximumValue != null && value > field.maximumValue!) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.aboveMaximum,
            key: field.key,
          ),
        );
      }
    }
    if (field.options.isNotEmpty) {
      final accepted = field.options.map((option) => option.value).toSet();
      final values = value is Iterable ? value : [value];
      if (values.map(supportString).any((item) => !accepted.contains(item))) {
        issues.add(
          CatalogueSubmissionIssue(
            code: CatalogueSubmissionIssueCode.invalidOption,
            key: field.key,
          ),
        );
      }
    }
  }

  static bool _isDependencyMet(
    CatalogueFieldSchema field,
    Map<String, Object?> responses,
  ) {
    final dependency = field.dependency;
    if (dependency == null) return true;
    final value = responses[dependency.fieldKey];
    if (value is Iterable) {
      return value.map(supportString).any(dependency.acceptedValues.contains);
    }
    return dependency.acceptedValues.contains(supportString(value));
  }

  static bool _isEmpty(Object? value) {
    return value == null ||
        (value is String && value.trim().isEmpty) ||
        (value is Iterable && value.isEmpty);
  }
}

enum ServiceRequestCancellationIssue {
  notOwner,
  workflowDisallowsCancellation,
  statusDisallowsCancellation,
  reasonRequired,
}

class ServiceRequestCancellationValidation {
  ServiceRequestCancellationValidation(
    Iterable<ServiceRequestCancellationIssue> issues,
  ) : issues = List<ServiceRequestCancellationIssue>.unmodifiable(issues);

  final List<ServiceRequestCancellationIssue> issues;

  bool get isValid => issues.isEmpty;
}

abstract final class ServiceRequestCancellationPolicy {
  static ServiceRequestCancellationValidation validateSelfService({
    required ServiceRequest request,
    required String actorUserId,
    required String reason,
  }) {
    final issues = <ServiceRequestCancellationIssue>[];
    if (request.requestedForUserId != actorUserId.trim()) {
      issues.add(ServiceRequestCancellationIssue.notOwner);
    }
    if (!request.workflowAllowsCancellation) {
      issues.add(
        ServiceRequestCancellationIssue.workflowDisallowsCancellation,
      );
    }
    const selfServiceCancellableStatuses = {
      ServiceRequestStatus.draft,
      ServiceRequestStatus.submitted,
      ServiceRequestStatus.awaitingApproval,
    };
    if (!selfServiceCancellableStatuses.contains(request.status)) {
      issues.add(ServiceRequestCancellationIssue.statusDisallowsCancellation);
    }
    if (reason.trim().isEmpty) {
      issues.add(ServiceRequestCancellationIssue.reasonRequired);
    }
    return ServiceRequestCancellationValidation(issues);
  }

  static ServiceRequestCancellationValidation validateManager({
    required ServiceRequest request,
    required String reason,
  }) {
    final issues = <ServiceRequestCancellationIssue>[];
    if (request.isTerminal ||
        request.status == ServiceRequestStatus.fulfilled) {
      issues.add(ServiceRequestCancellationIssue.statusDisallowsCancellation);
    }
    if (reason.trim().isEmpty) {
      issues.add(ServiceRequestCancellationIssue.reasonRequired);
    }
    return ServiceRequestCancellationValidation(issues);
  }
}

abstract final class ServiceRequestRejectionPolicy {
  static void validate({
    required ItsmRole actorRole,
    required ServiceRequest request,
    required String reason,
  }) {
    if (actorRole != ItsmRole.manager) {
      throw StateError('Only a MANAGER may reject a service request.');
    }
    if (!request.canTransitionTo(ServiceRequestStatus.rejected)) {
      throw StateError(
        'A ${request.status.value} request cannot be rejected.',
      );
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'A rejection reason is required.',
      );
    }
  }
}
