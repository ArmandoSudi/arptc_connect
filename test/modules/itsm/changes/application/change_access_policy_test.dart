import 'package:arptc_connect/modules/itsm/changes/application/change_access_policy.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangeAccessPolicy', () {
    const policy = ChangeAccessPolicy();

    test('USER and ADMIN receive self-service but not operational access', () {
      for (final role in [ItsmRole.user, ItsmRole.admin]) {
        final session = _session(role);
        expect(
          () => policy.authorizeRequestScope(
            session,
            ChangeRequestScope.myActive,
          ),
          returnsNormally,
        );
        expect(
          () => policy.authorizeRequestScope(
            session,
            ChangeRequestScope.managerActive,
          ),
          throwsA(isA<ChangeAccessDenied>()),
        );
        expect(
          () => policy.authorizeCab(session),
          throwsA(isA<ChangeAccessDenied>()),
        );
      }
    });

    test('MANAGER alone receives operational and CAB access', () {
      final session = _session(ItsmRole.manager);
      expect(() => policy.authorizeOperational(session), returnsNormally);
      expect(() => policy.authorizeCab(session), returnsNormally);
      expect(
        () => policy.authorizeCalendar(
          session,
          ChangeCalendarScope.operational,
        ),
        returnsNormally,
      );
    });

    test('calendar keeps executive and operational scopes separate', () {
      expect(
        () => policy.authorizeCalendar(
          _session(ItsmRole.admin),
          ChangeCalendarScope.executive,
        ),
        returnsNormally,
      );
      expect(
        () => policy.authorizeCalendar(
          _session(ItsmRole.manager),
          ChangeCalendarScope.executive,
        ),
        throwsA(isA<ChangeAccessDenied>()),
      );
      expect(
        () => policy.authorizeCalendar(
          _session(ItsmRole.user),
          ChangeCalendarScope.ownAndPublished,
        ),
        returnsNormally,
      );
    });
  });
}

ItsmSession _session(ItsmRole role) => ItsmSession(
      sessionKey: '${role.value}|user@example.com',
      userId: '${role.value.toLowerCase()}-1',
      email: 'user@example.com',
      displayName: 'Test user',
      role: role,
    );
