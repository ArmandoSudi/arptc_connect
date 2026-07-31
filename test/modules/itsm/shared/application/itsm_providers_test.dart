import 'dart:async';

import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provider family requests have stable value equality', () {
    final first = ItsmFirstPageRequest(
      query: ItsmWorkItemQuery(
        scope: ItsmWorkItemScope.myActive,
        statuses: const ['OPEN'],
      ),
      limit: 20,
    );
    final second = ItsmFirstPageRequest(
      query: ItsmWorkItemQuery(
        scope: ItsmWorkItemScope.myActive,
        statuses: const ['open'],
      ),
      limit: 20,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(
      () => ItsmFirstPageRequest(
        query: ItsmWorkItemQuery(scope: ItsmWorkItemScope.myActive),
        limit: 101,
      ),
      throwsRangeError,
    );
  });

  test('page provider scopes repository calls to the current session',
      () async {
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [
        currentAuthSessionKeyProvider.overrideWithValue(
          'user-1|agent@example.com',
        ),
        itsmSessionProvider.overrideWith(
          (ref) => Stream.value(_session(ItsmRole.user)),
        ),
        itsmWorkItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final request = ItsmWorkItemPageRequest(
      query: ItsmWorkItemQuery(scope: ItsmWorkItemScope.myActive),
      page: PageRequest(limit: 12),
    );
    final result = await container.read(
      itsmWorkItemPageProvider(request).future,
    );

    expect(result.items, isEmpty);
    expect(repository.lastPrincipal?.userId, 'user-1');
    expect(repository.lastPrincipal?.sessionKey, 'user-1|agent@example.com');
    expect(repository.lastPage?.limit, 12);
  });

  test('provider denies operational reads before calling repository', () async {
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [
        currentAuthSessionKeyProvider.overrideWithValue(
          'user-1|agent@example.com',
        ),
        itsmSessionProvider.overrideWith(
          (ref) => Stream.value(_session(ItsmRole.user)),
        ),
        itsmWorkItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final request = ItsmWorkItemPageRequest(
      query: ItsmWorkItemQuery(scope: ItsmWorkItemScope.managerActive),
      page: PageRequest(),
    );

    await expectLater(
      container.read(itsmWorkItemPageProvider(request).future),
      throwsA(isA<ItsmAccessDeniedException>()),
    );
    expect(repository.fetchCount, 0);
  });

  test('session override keeps provider tests independent of Firebase',
      () async {
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [
        currentAuthSessionKeyProvider.overrideWithValue(
          'user-1|agent@example.com',
        ),
        itsmSessionProvider.overrideWith(
          (ref) => Stream.value(_session(ItsmRole.manager)),
        ),
        itsmWorkItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final request = ItsmFirstPageRequest(
      query: ItsmWorkItemQuery(scope: ItsmWorkItemScope.assignedToMe),
      limit: 10,
    );
    final subscription = container.listen(
      itsmWorkItemFirstPageProvider(request),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final result = await container.read(
      itsmWorkItemFirstPageProvider(request).future,
    );

    expect(result, isEmpty);
    expect(repository.lastPrincipal?.role, ItsmRole.manager);
    expect(repository.lastLimit, 10);
  });

  test(
      'live work-item provider resubscribes when the authenticated user changes',
      () async {
    final sessions = StreamController<ItsmSession?>();
    final sessionKeys = StateProvider<String?>((ref) => 'user-1');
    final repository = _RecordingRepository();
    final container = ProviderContainer(
      overrides: [
        currentAuthSessionKeyProvider.overrideWith(
          (ref) => ref.watch(sessionKeys),
        ),
        itsmSessionProvider.overrideWith((ref) => sessions.stream),
        itsmWorkItemRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });

    final request = ItsmFirstPageRequest(
      query: ItsmWorkItemQuery(scope: ItsmWorkItemScope.myActive),
      limit: 10,
    );
    final subscription = container.listen(
      itsmWorkItemFirstPageProvider(request),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final keySubscription = container.listen<String?>(
      currentAuthSessionKeyProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(keySubscription.close);

    sessions.add(_session(ItsmRole.user));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sessions.add(
      const ItsmSession(
        sessionKey: 'user-2|second@example.com',
        userId: 'user-2',
        email: 'second@example.com',
        displayName: 'Second Agent',
        role: ItsmRole.user,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    container.read(sessionKeys.notifier).state = 'user-2';
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(currentAuthSessionKeyProvider), 'user-2');

    expect(
      repository.principals.map((principal) => principal.userId),
      containsAllInOrder(['user-1', 'user-2']),
    );
  });
}

class _RecordingRepository implements ItsmWorkItemRepository {
  final List<ItsmQueryPrincipal> principals = [];
  ItsmQueryPrincipal? lastPrincipal;
  PageRequest? lastPage;
  int? lastLimit;
  int fetchCount = 0;

  @override
  Future<PageResult<ItsmWorkItemSummary>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemQuery query,
    required PageRequest page,
  }) async {
    fetchCount++;
    lastPrincipal = principal;
    principals.add(principal);
    lastPage = page;
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Stream<ItsmWorkItemSummary?> watchById({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemType type,
    required String id,
  }) {
    lastPrincipal = principal;
    principals.add(principal);
    return Stream.value(null);
  }

  @override
  Stream<List<ItsmWorkItemSummary>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemQuery query,
    required int limit,
  }) {
    lastPrincipal = principal;
    principals.add(principal);
    lastLimit = limit;
    return Stream<List<ItsmWorkItemSummary>>.multi(
      (controller) => controller.add(const []),
    );
  }
}

ItsmSession _session(ItsmRole role) {
  return ItsmSession(
    sessionKey: 'user-1|agent@example.com',
    userId: 'user-1',
    email: 'agent@example.com',
    displayName: 'Agent',
    role: role,
  );
}
