import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';
import '../data/service_request_repository.dart';
import '../domain/support_domain.dart';

class ServiceRequestAccessPolicy {
  const ServiceRequestAccessPolicy();

  void authorizeQuery(ItsmSession session, ServiceRequestScope scope) {
    final operational = scope == ServiceRequestScope.managerActive ||
        scope == ServiceRequestScope.managerClosed ||
        scope == ServiceRequestScope.assignedToMe;
    if (operational && session.role != ItsmRole.manager) {
      throw ServiceRequestAccessDenied(
        'Role ${session.role.value} cannot access ${scope.name}.',
      );
    }
  }

  void authorizeRead(ItsmSession session, ServiceRequest request) {
    if (session.role == ItsmRole.manager) return;
    if (!request.selfServiceVisible ||
        request.confidentiality == ItsmConfidentiality.restricted ||
        request.requestedForUserId != session.userId) {
      throw const ServiceRequestAccessDenied(
        'This service request is not available to the active user.',
      );
    }
  }

  CataloguePrincipal cataloguePrincipal(
    ItsmSession session, {
    String? departmentId,
    String? serviceId,
  }) {
    return CataloguePrincipal(
      userId: session.userId,
      role: session.role,
      departmentId: departmentId,
      serviceId: serviceId,
    );
  }

  CatalogueSubmissionValidation validateCreate({
    required ItsmSession session,
    required ServiceCatalogueItem item,
    required ServiceRequestTarget target,
    required DateTime at,
    required Map<String, Object?> responses,
    Iterable<SubmittedDocument> documents = const [],
    String? departmentId,
    String? serviceId,
  }) {
    final isSelf = target.userId == session.userId;
    if (!isSelf && session.role != ItsmRole.manager) {
      throw const ServiceRequestAccessDenied(
        'USER and ADMIN can create requests only for themselves.',
      );
    }
    if (!isSelf &&
        session.role == ItsmRole.manager &&
        !item.allowManagerRequestOnBehalf) {
      throw const ServiceRequestAccessDenied(
        'This catalogue item does not allow requests on behalf of a user.',
      );
    }
    return CatalogueSubmissionValidator.validate(
      item: item,
      principal: CataloguePrincipal(
        userId: target.userId,
        role: session.role,
        departmentId: target.departmentId ?? departmentId,
        serviceId: target.serviceId ?? serviceId,
      ),
      at: at,
      responses: responses,
      documents: documents,
    );
  }

  void authorizeOperationalCommand(ItsmSession session) {
    if (session.role != ItsmRole.manager) {
      throw const ServiceRequestAccessDenied(
        'Only a MANAGER may process service requests.',
      );
    }
  }

  ServiceRequestCancellationValidation validateCancellation({
    required ItsmSession session,
    required ServiceRequest request,
    required String reason,
  }) {
    if (session.role == ItsmRole.manager) {
      return ServiceRequestCancellationPolicy.validateManager(
        request: request,
        reason: reason,
      );
    }
    return ServiceRequestCancellationPolicy.validateSelfService(
      request: request,
      actorUserId: session.userId,
      reason: reason,
    );
  }

  void authorizeCompletionConfirmation({
    required ItsmSession session,
    required ServiceRequest request,
  }) {
    if (request.requestedForUserId != session.userId ||
        request.status != ServiceRequestStatus.fulfilled) {
      throw const ServiceRequestAccessDenied(
        'Only the affected user may confirm a fulfilled request.',
      );
    }
  }
}

class ServiceRequestTarget {
  ServiceRequestTarget(
    this.userId, {
    this.departmentId,
    this.serviceId,
  }) {
    supportRequire(userId, 'userId');
  }

  final String userId;
  final String? departmentId;
  final String? serviceId;
}

class ServiceRequestAccessDenied implements Exception {
  const ServiceRequestAccessDenied(this.message);

  final String message;

  @override
  String toString() => 'ServiceRequestAccessDenied($message)';
}

class ServiceRequestValidationException implements Exception {
  const ServiceRequestValidationException(this.message);

  final String message;

  @override
  String toString() => 'ServiceRequestValidationException($message)';
}
