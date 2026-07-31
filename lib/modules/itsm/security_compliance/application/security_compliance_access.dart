import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';

enum SecurityComplianceScope { selfService, operational }

class SecurityComplianceApplicationPolicy {
  const SecurityComplianceApplicationPolicy();

  bool canUseSelfService(ItsmSession session) =>
      session.role == ItsmRole.user || session.role == ItsmRole.admin;

  bool canSubmitException(ItsmSession session) =>
      session.role == ItsmRole.user ||
      session.role == ItsmRole.admin ||
      session.role == ItsmRole.manager;

  bool canOperate(ItsmSession session) => session.role == ItsmRole.manager;

  void authorize(ItsmSession session, SecurityComplianceScope scope) {
    final allowed = switch (scope) {
      SecurityComplianceScope.selfService => canUseSelfService(session),
      SecurityComplianceScope.operational => canOperate(session),
    };
    if (!allowed) {
      throw SecurityComplianceAccessDenied(
        'Role ${session.role.value} cannot access ${scope.name}.',
      );
    }
  }

  void authorizeExceptionSubmission(ItsmSession session) {
    if (!canSubmitException(session)) {
      throw const SecurityComplianceAccessDenied(
        'An ITSM role is required to submit a security exception.',
      );
    }
  }
}

class SecurityComplianceAccessDenied implements Exception {
  const SecurityComplianceAccessDenied(this.message);

  final String message;

  @override
  String toString() => 'SecurityComplianceAccessDenied($message)';
}
