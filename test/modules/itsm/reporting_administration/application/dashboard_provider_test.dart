import 'dart:async';

import 'package:arptc_connect/modules/itsm/reporting_administration/application/reporting_administration_application.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/data/report_snapshot_repository.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/domain/reporting_administration_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session switch rebuilds snapshot query for the new audience', () async {
    final sessions = StreamController<ItsmSession?>();
    final repository = _RecordingSnapshotRepository();
    final container = ProviderContainer(overrides: [
      itsmSessionProvider.overrideWith((ref) => sessions.stream),
      reportSnapshotRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
    final listener = container.listen(
        currentReportSnapshotProvider(null), (_, __) {},
        fireImmediately: true);
    addTearDown(listener.close);

    sessions.add(_session(ItsmRole.manager));
    await _waitFor(() => repository.audiences.length == 1);
    sessions.add(_session(ItsmRole.admin));
    await _waitFor(() => repository.audiences.length == 2);

    expect(repository.audiences, [ItsmRole.manager, ItsmRole.admin]);
    expect(repository.types,
        [ReportSnapshotType.operational, ReportSnapshotType.executive]);
  });
}

ItsmSession _session(ItsmRole role) => ItsmSession(
      sessionKey: '${role.value}|session',
      userId: role.value.toLowerCase(),
      email: '${role.value.toLowerCase()}@example.com',
      displayName: role.value,
      role: role,
    );

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for provider state.');
}

class _RecordingSnapshotRepository implements ReportSnapshotRepository {
  final List<ItsmRole> audiences = [];
  final List<ReportSnapshotType> types = [];

  @override
  Stream<ItsmReportSnapshot?> watchCurrent(
      {required ItsmQueryPrincipal principal,
      required ReportSnapshotQuery query}) {
    audiences.add(query.audience);
    types.add(query.type);
    return Stream.value(null);
  }

  @override
  Future<PageResult<ItsmReportSnapshot>> fetchHistory(
          {required ItsmQueryPrincipal principal,
          required ReportSnapshotQuery query,
          required PageRequest page}) async =>
      PageResult(items: const [], hasMore: false);
}
