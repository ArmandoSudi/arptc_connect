import 'dart:async';

import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/news/data/firestore_news_repository.dart';
import 'package:arptc_connect/modules/news/data/news_repository.dart';
import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _testAuthorizedSessionProvider =
    StateProvider<AuthorizedSessionState>((ref) {
  return const AuthorizedSessionState.unauthenticated();
});

void main() {
  test('published news subscription follows the authenticated session',
      () async {
    final repository = _TrackingNewsRepository();
    final container = ProviderContainer(
      overrides: [
        authorizedSessionProvider.overrideWith(
          (ref) => ref.watch(_testAuthorizedSessionProvider),
        ),
        newsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(
      publishedNewsPostsProvider,
      (_, __) {},
      fireImmediately: true,
    );

    await container.pump();
    expect(repository.watchCallCount, 0);
    expect(repository.activeListenerCount, 0);

    container.read(_testAuthorizedSessionProvider.notifier).state =
        AuthorizedSessionState.authenticated(_session('user-a'));
    await container.pump();
    expect(repository.watchCallCount, 1);
    expect(repository.activeListenerCount, 1);

    container.read(_testAuthorizedSessionProvider.notifier).state =
        const AuthorizedSessionState.unauthenticated();
    await container.pump();
    expect(repository.activeListenerCount, 0);

    container.read(_testAuthorizedSessionProvider.notifier).state =
        AuthorizedSessionState.authenticated(_session('user-b'));
    await container.pump();
    expect(repository.watchCallCount, 2);
    expect(repository.activeListenerCount, 1);

    subscription.close();
    container.dispose();
    await repository.dispose();
  });
}

AuthorizedSession _session(String userId) {
  return AuthorizedSession(
    sessionKey: '$userId|$userId@test.cd',
    userId: userId,
    email: '$userId@test.cd',
    displayName: userId,
    profile: {
      'id': userId,
      'email': '$userId@test.cd',
      'isActive': true,
      'modulePermissions': const {'news': 'USER'},
    },
    modulePermissions: const {'news': 'USER'},
  );
}

class _TrackingNewsRepository implements NewsRepository {
  final List<StreamController<List<NewsPost>>> _controllers = [];

  int watchCallCount = 0;
  int activeListenerCount = 0;

  @override
  Stream<List<NewsPost>> watchPublishedPosts() {
    watchCallCount += 1;
    final controller = StreamController<List<NewsPost>>.broadcast(
      onListen: () => activeListenerCount += 1,
      onCancel: () => activeListenerCount -= 1,
    );
    _controllers.add(controller);
    return controller.stream;
  }

  Future<void> dispose() async {
    for (final controller in _controllers) {
      await controller.close();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
