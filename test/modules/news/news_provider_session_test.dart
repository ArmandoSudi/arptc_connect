import 'dart:async';

import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/news/data/firestore_news_repository.dart';
import 'package:arptc_connect/modules/news/data/news_repository.dart';
import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _testSessionKeyProvider = StateProvider<String?>((ref) => null);

void main() {
  test('published news subscription follows the authenticated session',
      () async {
    final repository = _TrackingNewsRepository();
    final container = ProviderContainer(
      overrides: [
        currentAuthSessionKeyProvider.overrideWith(
          (ref) => ref.watch(_testSessionKeyProvider),
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

    container.read(_testSessionKeyProvider.notifier).state = 'user-a|a@test.cd';
    await container.pump();
    expect(repository.watchCallCount, 1);
    expect(repository.activeListenerCount, 1);

    container.read(_testSessionKeyProvider.notifier).state = null;
    await container.pump();
    expect(repository.activeListenerCount, 0);

    container.read(_testSessionKeyProvider.notifier).state = 'user-b|b@test.cd';
    await container.pump();
    expect(repository.watchCallCount, 2);
    expect(repository.activeListenerCount, 1);

    subscription.close();
    container.dispose();
    await repository.dispose();
  });
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
