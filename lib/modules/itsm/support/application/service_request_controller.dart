import '../../shared/application/itsm_command_executor.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/data/trusted_command_gateways.dart';
import '../../shared/domain/approval.dart';
import '../../shared/domain/itsm_common.dart';
import '../data/service_request_command_gateway.dart';
import '../domain/support_domain.dart';
import 'service_request_access_policy.dart';

class ServiceRequestController {
  ServiceRequestController({
    required ItsmSession session,
    required ServiceRequestAccessPolicy accessPolicy,
    required ServiceRequestCommandGateway gateway,
    ItsmCommandExecutor? executor,
  })  : _session = session,
        _accessPolicy = accessPolicy,
        _gateway = gateway,
        _executor = executor ?? ItsmCommandExecutor();

  final ItsmSession _session;
  final ServiceRequestAccessPolicy _accessPolicy;
  final ServiceRequestCommandGateway _gateway;
  final ItsmCommandExecutor _executor;
  final Map<String, Future<ServiceRequestSubmissionReceipt>>
      _submissionInFlight = {};

  Future<ServiceRequestSubmissionReceipt> create({
    required CreateServiceRequestCommand command,
    required DateTime at,
    String? departmentId,
    String? serviceId,
    String? locationId,
    String? positionValue,
  }) {
    _validateContext(command.context);
    final validation = _accessPolicy.validateCreate(
      session: _session,
      item: command.catalogueItem,
      target: ServiceRequestTarget(
        command.requestedFor.userId,
        departmentId: command.requestedFor.departmentId,
        serviceId: command.requestedFor.serviceId,
      ),
      at: at,
      responses: command.responses,
      documents: command.documents.map(
        (document) => document.toSubmittedDocument(),
      ),
      departmentId: departmentId,
      serviceId: serviceId,
      locationId: locationId,
      positionValue: positionValue,
    );
    if (!validation.isValid) {
      throw ServiceRequestValidationException(
        'The catalogue submission has ${validation.issues.length} issue(s).',
      );
    }
    final key = command.context.idempotencyKey.trim();
    final existing = _submissionInFlight[key];
    if (existing != null) return existing;
    late final Future<ServiceRequestSubmissionReceipt> pending;
    pending = _gateway.create(command).whenComplete(() {
      if (identical(_submissionInFlight[key], pending)) {
        _submissionInFlight.remove(key);
      }
    });
    _submissionInFlight[key] = pending;
    return pending;
  }

  Future<ItsmCommandReceipt> transitionOperational(
    TransitionServiceRequestCommand command,
  ) {
    _validateContext(command.context);
    _accessPolicy.authorizeOperationalCommand(_session);
    if (command.targetStatus == ServiceRequestStatus.rejected) {
      ServiceRequestRejectionPolicy.validate(
        actorRole: _session.role,
        request: command.request,
        reason: command.reason,
      );
    }
    return _executor.executeOnce(
      command.context,
      () => _gateway.transition(command),
    );
  }

  Future<ItsmCommandReceipt> cancel({
    required ItsmCommandContext context,
    required ServiceRequest request,
    required String transitionId,
    required String reason,
  }) {
    _validateContext(context);
    final validation = _accessPolicy.validateCancellation(
      session: _session,
      request: request,
      reason: reason,
    );
    if (!validation.isValid) {
      throw ServiceRequestValidationException(
        'The request cannot be cancelled: '
        '${validation.issues.map((issue) => issue.name).join(', ')}.',
      );
    }
    final command = TransitionServiceRequestCommand(
      context: context,
      request: request,
      transitionId: transitionId,
      targetStatus: ServiceRequestStatus.cancelled,
      reason: reason,
    );
    return _executor.executeOnce(
      context,
      () => _gateway.transition(command),
    );
  }

  Future<ItsmCommandReceipt> confirmCompletion({
    required ItsmCommandContext context,
    required ServiceRequest request,
    required String transitionId,
  }) {
    _validateContext(context);
    _accessPolicy.authorizeCompletionConfirmation(
      session: _session,
      request: request,
    );
    final command = TransitionServiceRequestCommand(
      context: context,
      request: request,
      transitionId: transitionId,
      targetStatus: ServiceRequestStatus.closed,
    );
    return _executor.executeOnce(
      context,
      () => _gateway.transition(command),
    );
  }

  Future<ItsmCommandReceipt> decideApproval(
    DecideServiceRequestApprovalCommand command,
  ) {
    _validateContext(command.context);
    _accessPolicy.authorizeOperationalCommand(_session);
    if (command.decision == ApprovalDecision.reject &&
        command.comment.trim().isEmpty) {
      throw const ServiceRequestValidationException(
        'A rejection reason is required.',
      );
    }
    return _executor.executeOnce(
      command.context,
      () => _gateway.decideApproval(command),
    );
  }

  Future<ItsmCommandReceipt> assign(AssignServiceRequestCommand command) {
    _validateContext(command.context);
    _accessPolicy.authorizeOperationalCommand(_session);
    return _executor.executeOnce(
      command.context,
      () => _gateway.assign(command),
    );
  }

  Future<ItsmCommandReceipt> updateTask(
    UpdateServiceRequestTaskCommand command,
  ) {
    _validateContext(command.context);
    _accessPolicy.authorizeOperationalCommand(_session);
    return _executor.executeOnce(
      command.context,
      () => _gateway.updateTask(command),
    );
  }

  Future<ItsmCommandReceipt> addComment(
    AddServiceRequestCommentCommand command,
  ) {
    _validateContext(command.context);
    _accessPolicy.authorizeOperationalCommand(_session);
    return _executor.executeOnce(
      command.context,
      () => _gateway.addComment(command),
    );
  }

  Future<ItsmCommandReceipt> linkRecord(
    LinkServiceRequestRecordCommand command,
  ) {
    _validateContext(command.context);
    _accessPolicy.authorizeOperationalCommand(_session);
    return _executor.executeOnce(
      command.context,
      () => _gateway.linkRecord(command),
    );
  }

  bool isExecuting(String idempotencyKey) {
    final key = idempotencyKey.trim();
    return _submissionInFlight.containsKey(key) || _executor.isExecuting(key);
  }

  void _validateContext(ItsmCommandContext context) {
    if (context.actorUserId != _session.userId ||
        context.actorRole != _session.role) {
      throw const ServiceRequestAccessDenied(
        'The command actor does not match the active ITSM session.',
      );
    }
    if (context.actorRole == ItsmRole.admin &&
        context.actorUserId != _session.userId) {
      throw const ServiceRequestAccessDenied(
        'ADMIN commands are limited to the active self-service account.',
      );
    }
  }
}
