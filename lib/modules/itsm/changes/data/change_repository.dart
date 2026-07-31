import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/collaboration.dart';
import '../../shared/domain/itsm_audit_event.dart';
import '../../shared/domain/pagination.dart';
import '../application/change_access_policy.dart';
import '../domain/changes_domain.dart';

class ChangeRequestQuery {
  const ChangeRequestQuery({
    required this.scope,
    this.type,
    this.status,
    this.risk,
  }) : assert(
          (type == null ? 0 : 1) +
                  (status == null ? 0 : 1) +
                  (risk == null ? 0 : 1) <=
              1,
          'Use one indexed change-request filter at a time.',
        );

  final ChangeRequestScope scope;
  final ChangeType? type;
  final ChangeStatus? status;
  final ChangeRiskLevel? risk;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeRequestQuery &&
          scope == other.scope &&
          type == other.type &&
          status == other.status &&
          risk == other.risk;

  @override
  int get hashCode => Object.hash(scope, type, status, risk);
}

class ChangeCalendarQuery {
  ChangeCalendarQuery({
    required this.scope,
    required DateTime startsAt,
    required DateTime endsAt,
    this.serviceId,
    this.configurationItemId,
    this.type,
    this.status,
    this.hasConflict,
  })  : startsAt = startsAt.toUtc(),
        endsAt = endsAt.toUtc() {
    if (!this.endsAt.isAfter(this.startsAt)) {
      throw ArgumentError('Calendar end must be after its start.');
    }
    final filterCount = <bool>[
      serviceId?.trim().isNotEmpty ?? false,
      configurationItemId?.trim().isNotEmpty ?? false,
      type != null,
      status != null,
      hasConflict != null,
    ].where((enabled) => enabled).length;
    if (filterCount > 1) {
      throw ArgumentError(
        'Use one indexed calendar filter at a time.',
      );
    }
  }

  final ChangeCalendarScope scope;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? serviceId;
  final String? configurationItemId;
  final ChangeType? type;
  final ChangeStatus? status;
  final bool? hasConflict;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeCalendarQuery &&
          scope == other.scope &&
          startsAt == other.startsAt &&
          endsAt == other.endsAt &&
          serviceId == other.serviceId &&
          configurationItemId == other.configurationItemId &&
          type == other.type &&
          status == other.status &&
          hasConflict == other.hasConflict;

  @override
  int get hashCode => Object.hash(
        scope,
        startsAt,
        endsAt,
        serviceId,
        configurationItemId,
        type,
        status,
        hasConflict,
      );
}

abstract interface class ChangeRepository {
  Future<PageResult<ChangeRequest>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ChangeRequestQuery query,
    required PageRequest page,
  });

  Stream<List<ChangeRequest>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ChangeRequestQuery query,
    int limit = PageRequest.defaultLimit,
  });

  Stream<ChangeRequest?> watchById({
    required ItsmQueryPrincipal principal,
    required String id,
  });

  Stream<List<CabMeeting>> watchCabMeetings({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  });

  Stream<List<ChangeCalendarEntry>> watchCalendar({
    required ItsmQueryPrincipal principal,
    required ChangeCalendarQuery query,
    int limit = PageRequest.maximumLimit,
  });

  Stream<List<ItsmComment>> watchComments({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  });

  Stream<List<ItsmAttachment>> watchAttachments({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  });

  Stream<List<ItsmAuditEvent>> watchAuditTimeline({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  });
}

class ChangeRepositoryException implements Exception {
  const ChangeRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ChangeRepositoryException($message)';
}
