import 'dart:async';

import 'package:arptc_connect/modules/itsm/changes/application/change_providers.dart';
import 'package:arptc_connect/modules/itsm/changes/data/change_repository.dart';
import 'package:arptc_connect/modules/itsm/changes/domain/changes_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_audit_event.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collaboration request normalizes identity and enforces bounds', () {
    final request = ChangeCollaborationRequest(
      changeId: '  change-1  ',
      limit: 25,
    );
    expect(request.changeId, 'change-1');
    expect(request.limit, 25);
    expect(
      () => ChangeCollaborationRequest(changeId: 'change-1', limit: 0),
      throwsRangeError,
    );
    expect(
      () => ChangeCollaborationRequest(
        changeId: 'change-1',
        limit: PageRequest.maximumLimit + 1,
      ),
      throwsRangeError,
    );
  });

  test('comment provider resubscribes with the successive user session',
      () async {
    final sessions = StreamController<ItsmSession?>();
    final repository = _RecordingChangeRepository();
    final container = ProviderContainer(
      overrides: [
        itsmSessionProvider.overrideWith((ref) => sessions.stream),
        changeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });

    final request = ChangeCollaborationRequest(changeId: 'change-1', limit: 8);
    final subscription = container.listen(
      changeCommentsProvider(request),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    sessions.add(_session('user-1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sessions.add(_session('user-2'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.commentPrincipals.map((item) => item.userId), [
      'user-1',
      'user-2',
    ]);
    expect(repository.lastCommentLimit, 8);
  });
}

ItsmSession _session(String userId) => ItsmSession(
      sessionKey: '$userId|$userId@example.com',
      userId: userId,
      email: '$userId@example.com',
      displayName: userId,
      role: ItsmRole.user,
    );

class _RecordingChangeRepository implements ChangeRepository {
  final commentPrincipals = <ItsmQueryPrincipal>[];
  int? lastCommentLimit;

  @override
  Stream<List<ItsmComment>> watchComments({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) {
    commentPrincipals.add(principal);
    lastCommentLimit = limit;
    return Stream.value(const []);
  }

  @override
  Stream<List<ItsmAttachment>> watchAttachments({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) =>
      Stream.value(const []);

  @override
  Stream<List<ItsmAuditEvent>> watchAuditTimeline({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) =>
      Stream.value(const []);

  @override
  Future<PageResult<ChangeRequest>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ChangeRequestQuery query,
    required PageRequest page,
  }) async =>
      PageResult(items: const [], hasMore: false);

  @override
  Stream<List<ChangeRequest>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ChangeRequestQuery query,
    int limit = PageRequest.defaultLimit,
  }) =>
      Stream.value(const []);

  @override
  Stream<ChangeRequest?> watchById({
    required ItsmQueryPrincipal principal,
    required String id,
  }) =>
      Stream.value(null);

  @override
  Stream<List<CabMeeting>> watchCabMeetings({
    required ItsmQueryPrincipal principal,
    required String changeId,
    int limit = PageRequest.defaultLimit,
  }) =>
      Stream.value(const []);

  @override
  Stream<List<ChangeCalendarEntry>> watchCalendar({
    required ItsmQueryPrincipal principal,
    required ChangeCalendarQuery query,
    int limit = PageRequest.maximumLimit,
  }) =>
      Stream.value(const []);
}
