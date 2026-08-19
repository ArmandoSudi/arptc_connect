import 'dart:async';

import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/data/incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _testAuthorizedSessionProvider =
    StateProvider<AuthorizedSessionState>((ref) {
  return const AuthorizedSessionState.unauthenticated();
});
final _testIncidentRoleProvider =
    StateProvider<IncidentRole>((ref) => IncidentRole.none);

void main() {
  test('manager incident subscription follows authenticated sessions',
      () async {
    final repository = _TrackingIncidentRepository();
    final container = ProviderContainer(
      overrides: [
        authorizedSessionProvider.overrideWith(
          (ref) => ref.watch(_testAuthorizedSessionProvider),
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

    container.read(_testAuthorizedSessionProvider.notifier).state =
        AuthorizedSessionState.authenticated(_session('manager-a'));
    await container.pump();
    expect(repository.watchCallCount, 0);

    container.read(_testIncidentRoleProvider.notifier).state =
        IncidentRole.manager;
    await container.pump();
    expect(repository.watchCallCount, 1);
    expect(repository.activeListenerCount, 1);

    container.read(_testAuthorizedSessionProvider.notifier).state =
        const AuthorizedSessionState.unauthenticated();
    await container.pump();
    expect(repository.activeListenerCount, 0);

    container.read(_testAuthorizedSessionProvider.notifier).state =
        AuthorizedSessionState.authenticated(_session('manager-b'));
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
      'modulePermissions': const {'ticketing': 'MANAGER'},
    },
    modulePermissions: const {'ticketing': 'MANAGER'},
  );
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
