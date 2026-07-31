import 'dart:collection';
import 'dart:typed_data';

import '../../shared/data/trusted_command_gateways.dart';
import '../data/service_request_command_gateway.dart';
import '../domain/support_domain.dart';
import 'service_request_access_policy.dart';

class ServiceRequestPickedFile {
  ServiceRequestPickedFile({
    required this.fileName,
    required this.contentType,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes);

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class ServiceRequestFilePicker {
  Future<ServiceRequestPickedFile?> pick();
}

class ServiceRequestFormState {
  ServiceRequestFormState({
    required this.catalogueItem,
    required this.requestedFor,
    this.title = '',
    this.description = '',
    Map<String, Object?> responses = const {},
    Iterable<ServiceRequestSubmissionDocument> documents = const [],
    this.isSubmitting = false,
  })  : responses = UnmodifiableMapView(Map.of(responses)),
        documents = List.unmodifiable(documents);

  final ServiceCatalogueItem catalogueItem;
  final ServiceRequestTargetUser requestedFor;
  final String title;
  final String description;
  final Map<String, Object?> responses;
  final List<ServiceRequestSubmissionDocument> documents;
  final bool isSubmitting;

  ServiceRequestFormState copyWith({
    ServiceRequestTargetUser? requestedFor,
    String? title,
    String? description,
    Map<String, Object?>? responses,
    Iterable<ServiceRequestSubmissionDocument>? documents,
    bool? isSubmitting,
  }) {
    return ServiceRequestFormState(
      catalogueItem: catalogueItem,
      requestedFor: requestedFor ?? this.requestedFor,
      title: title ?? this.title,
      description: description ?? this.description,
      responses: responses ?? this.responses,
      documents: documents ?? this.documents,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  CatalogueSubmissionValidation validate({
    required CataloguePrincipal principal,
    required DateTime at,
  }) {
    return CatalogueSubmissionValidator.validate(
      item: catalogueItem,
      principal: principal,
      at: at,
      responses: responses,
      documents: documents.map((document) => document.toSubmittedDocument()),
    );
  }
}

class ServiceRequestFormController {
  ServiceRequestFormController(this.state);

  ServiceRequestFormState state;

  void setRequestedFor(ServiceRequestTargetUser user) {
    state = state.copyWith(requestedFor: user);
  }

  void setTitle(String value) => state = state.copyWith(title: value);

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  void setResponse(String key, Object? value) {
    final responses = Map<String, Object?>.of(state.responses);
    if (value == null || (value is String && value.trim().isEmpty)) {
      responses.remove(key);
    } else {
      responses[key] = value;
    }
    state = state.copyWith(responses: responses);
  }

  void setDocuments(Iterable<ServiceRequestSubmissionDocument> documents) {
    state = state.copyWith(documents: documents);
  }

  void addDocument({
    required CatalogueRequiredDocument requirement,
    required ServiceRequestPickedFile file,
    required String attachmentId,
  }) {
    CatalogueRequiredDocument? canonicalRequirement;
    for (final document in state.catalogueItem.requiredDocuments) {
      if (document.key == requirement.key) {
        canonicalRequirement = document;
        break;
      }
    }
    if (canonicalRequirement == null) {
      throw const ServiceRequestValidationException(
        'The document requirement does not belong to this catalogue item.',
      );
    }
    final matchingDocuments = state.documents
        .where(
            (document) => document.requirementId == canonicalRequirement!.key)
        .length;
    if (matchingDocuments >= canonicalRequirement.maximumFiles) {
      throw ServiceRequestValidationException(
        'A maximum of ${canonicalRequirement.maximumFiles} file(s) is allowed.',
      );
    }
    final normalizedContentType = file.contentType.trim().toLowerCase();
    if (canonicalRequirement.allowedContentTypes.isNotEmpty &&
        !canonicalRequirement.allowedContentTypes
            .contains(normalizedContentType)) {
      throw const ServiceRequestValidationException(
        'The selected file type is not allowed.',
      );
    }
    if (state.documents.any(
      (document) => document.attachmentId == attachmentId.trim(),
    )) {
      throw const ServiceRequestValidationException(
        'The attachment identifier is already in use.',
      );
    }
    final document = ServiceRequestSubmissionDocument(
      requirementId: canonicalRequirement.key,
      attachmentId: attachmentId,
      fileName: file.fileName,
      contentType: normalizedContentType,
      bytes: file.bytes,
    );
    state = state.copyWith(documents: [...state.documents, document]);
  }

  void removeDocument(String attachmentId) {
    state = state.copyWith(
      documents: state.documents
          .where((document) => document.attachmentId != attachmentId)
          .toList(growable: false),
    );
  }

  CreateServiceRequestCommand buildCommand(ItsmCommandContext context) {
    if (state.title.trim().isEmpty) {
      throw const ServiceRequestValidationException('A title is required.');
    }
    return CreateServiceRequestCommand(
      context: context,
      clientRequestId: context.idempotencyKey,
      catalogueItem: state.catalogueItem,
      requestedFor: state.requestedFor,
      title: state.title,
      description: state.description,
      responses: state.responses,
      documents: state.documents,
    );
  }
}
