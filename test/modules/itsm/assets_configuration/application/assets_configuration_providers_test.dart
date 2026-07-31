import 'dart:async';

import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_application.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'assets_configuration_test_support.dart';

void main() {
  test('my assets provider scopes reads to the active session', () async {
    final sessions = StreamController<ItsmSession?>();
    final port = RecordingAssetsReadPort();
    final container = ProviderContainer(
      overrides: [
        itsmSessionProvider.overrideWith((ref) => sessions.stream),
        assetsConfigurationReadPortProvider.overrideWithValue(port),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
    final subscription = container.listen(
      myAssetsProvider(10),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    sessions.add(assetSession(ItsmRole.user, userId: 'user-1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sessions.add(assetSession(ItsmRole.admin, userId: 'admin-1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      port.principals.map((principal) => principal.userId),
      containsAllInOrder(['user-1', 'admin-1']),
    );
  });

  test('operational provider rejects ADMIN before repository access', () async {
    final port = RecordingAssetsReadPort();
    final container = ProviderContainer(
      overrides: [
        itsmSessionProvider.overrideWith(
          (ref) => Stream.value(assetSession(ItsmRole.admin)),
        ),
        assetsConfigurationReadPortProvider.overrideWithValue(port),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      stockItemsProvider(10),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await expectLater(
      container.read(stockItemsProvider(10).future),
      throwsA(isA<AssetsConfigurationAccessDenied>()),
    );
    expect(port.principals, isEmpty);
  });

  test('self-service detail switches projection scope with the session',
      () async {
    final sessions = StreamController<ItsmSession?>();
    final port = RecordingAssetsReadPort();
    final container = ProviderContainer(
      overrides: [
        itsmSessionProvider.overrideWith((ref) => sessions.stream),
        assetsConfigurationReadPortProvider.overrideWithValue(port),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
    final provider = assetDetailProvider(
      AssetIdentity(id: 'asset-1', selfService: true),
    );
    final subscription = container.listen(
      provider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    sessions.add(assetSession(ItsmRole.user, userId: 'user-1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sessions.add(assetSession(ItsmRole.admin, userId: 'admin-1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      port.principals.map((principal) => principal.userId),
      containsAllInOrder(['user-1', 'admin-1']),
    );
    expect(port.selfServiceDetailAssetIds, ['asset-1', 'asset-1']);
    expect(port.operationalDetailAssetIds, isEmpty);
  });

  test('bounded provider validates maximum page size', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      myAssetsProvider(101),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await expectLater(
      container.read(myAssetsProvider(101).future),
      throwsA(isA<RangeError>()),
    );
  });
}
