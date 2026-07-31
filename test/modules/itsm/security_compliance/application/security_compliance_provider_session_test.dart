import 'dart:async';

import 'package:arptc_connect/modules/itsm/security_compliance/application/security_compliance_application.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/data/security_compliance_repository.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/domain/security_exception.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session switch rebuilds self-service query with the new principal',
      () async {
    final sessions = StreamController<ItsmSession?>();
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [
        itsmSessionProvider.overrideWith((ref) => sessions.stream),
        securityComplianceRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
    const request = SecurityComplianceFirstPageRequest(
      query: SecurityComplianceQuery(
        scope: SecurityComplianceScope.selfService,
      ),
    );
    final subscription = container.listen(
      securityExceptionsFirstPageProvider(request),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    sessions.add(_session('user-1'));
    await _waitFor(() => repository.userIds.length == 1);
    sessions.add(_session('user-2'));
    await _waitFor(() => repository.userIds.length == 2);

    expect(repository.userIds, ['user-1', 'user-2']);
  });
}

ItsmSession _session(String userId) => ItsmSession(
      sessionKey: '$userId|$userId@example.com',
      userId: userId,
      email: '$userId@example.com',
      displayName: userId,
      role: ItsmRole.user,
    );

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for provider state.');
}

class _RecordingRepository implements SecurityComplianceRepository {
  final List<String> userIds = [];

  @override
  Stream<List<SecurityException>> watchExceptions({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  }) {
    userIds.add(principal.userId);
    return Stream.value(const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
