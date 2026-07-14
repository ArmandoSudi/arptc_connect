import 'dart:async';

import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/data/incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _testSessionKeyProvider = StateProvider<String?>((ref) => null);
final _testIncidentRoleProvider =
    StateProvider<IncidentRole>((ref) => IncidentRole.none);

void main() {
  test('manager incident subscription follows authenticated sessions',
      () async {
    final repository = _TrackingIncidentRepository();
    final container = ProviderContainer(
      overrides: [
        currentAuthSessionKeyProvider.overrideWith(
          (ref) => ref.watch(_testSessionKeyProvider),
        ),
        currentUserIncidentRoleProvider.overrideWith(
          (ref) => AsyncValue.data(ref.watch(_testIncidentRoleProvider)),
        ),
        incidentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(
      managerOpenIncidentTicketsProvider,
      (_, __) {},
      fireImmediately: true,
    );

    await container.pump();
    expect(repository.watchCallCount, 0);
    expect(repository.activeListenerCount, 0);

    container.read(_testSessionKeyProvider.notifier).state =
        'manager-a|manager-a@test.cd';
    await container.pump();
    expect(repository.watchCallCount, 0);

    container.read(_testIncidentRoleProvider.notifier).state =
        IncidentRole.manager;
    await container.pump();
    expect(repository.watchCallCount, 1);
    expect(repository.activeListenerCount, 1);

    container.read(_testSessionKeyProvider.notifier).state = null;
    await container.pump();
    expect(repository.activeListenerCount, 0);

    container.read(_testSessionKeyProvider.notifier).state =
        'manager-b|manager-b@test.cd';
    await container.pump();
    expect(repository.watchCallCount, 2);
    expect(repository.activeListenerCount, 1);

    subscription.close();
    container.dispose();
    await repository.dispose();
  });
}

class _TrackingIncidentRepository implements IncidentRepository {
  final List<StreamController<List<IncidentTicket>>> _controllers = [];

  int watchCallCount = 0;
  int activeListenerCount = 0;

  @override
  Stream<List<IncidentTicket>> watchAllActiveTicketsForManagers() {
    watchCallCount += 1;
    final controller = StreamController<List<IncidentTicket>>.broadcast(
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
