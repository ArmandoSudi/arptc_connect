import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';

enum ChangeRequestScope {
  myActive,
  myHistory,
  managerActive,
  managerHistory,
}

enum ChangeCalendarScope { ownAndPublished, operational, executive }

class ChangeAccessPolicy {
  const ChangeAccessPolicy();

  bool canUseSelfService(ItsmSession session) =>
      session.role == ItsmRole.user ||
      session.role == ItsmRole.manager ||
      session.role == ItsmRole.admin;

  bool canOperate(ItsmSession session) => session.role == ItsmRole.manager;

  void authorizeRequestScope(ItsmSession session, ChangeRequestScope scope) {
    final operational = scope == ChangeRequestScope.managerActive ||
        scope == ChangeRequestScope.managerHistory;
    if (operational ? !canOperate(session) : !canUseSelfService(session)) {
      throw ChangeAccessDenied(
        'Role ${session.role.value} cannot access ${scope.name}.',
      );
    }
  }

  void authorizeOperational(ItsmSession session) {
    if (!canOperate(session)) {
      throw const ChangeAccessDenied(
        'Only a MANAGER can perform Change Management operations.',
      );
    }
  }

  void authorizeCalendar(ItsmSession session, ChangeCalendarScope scope) {
    final allowed = switch (scope) {
      ChangeCalendarScope.ownAndPublished => canUseSelfService(session),
      ChangeCalendarScope.operational => canOperate(session),
      ChangeCalendarScope.executive => session.role == ItsmRole.admin,
    };
    if (!allowed) {
      throw ChangeAccessDenied(
        'Role ${session.role.value} cannot access ${scope.name}.',
      );
    }
  }

  void authorizeCab(ItsmSession session) => authorizeOperational(session);
}

class ChangeAccessDenied implements Exception {
  const ChangeAccessDenied(this.message);

  final String message;

  @override
  String toString() => 'ChangeAccessDenied($message)';
}
