import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/incident_management/application/incident_dashboard_aggregator.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/data/incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_user.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('incident role subscription policy', () {
    test('USER subscribes only to their email-scoped queues', () async {
      final repository = _RecordingIncidentRepository();
      final container = _container(
        role: IncidentRole.user,
        repository: repository,
      );
      addTearDown(container.dispose);

      await container.read(myOpenIncidentTicketsProvider.future);
      await container.read(myClosedAndArchivedIncidentTicketsProvider.future);
      await container.read(managerOpenIncidentTicketsProvider.future);
      await container.read(adminAllIncidentTicketsProvider.future);

      expect(repository.myActiveEmails, ['agent@arptc.cd']);
      expect(repository.myHistoryEmails, ['agent@arptc.cd']);
      expect(repository.managerActiveCalls, 0);
      expect(repository.adminAllCalls, 0);
    });

    test('MANAGER receives operational queues but not ADMIN global queue',
        () async {
      final repository = _RecordingIncidentRepository();
      final container = _container(
        role: IncidentRole.manager,
        repository: repository,
      );
      addTearDown(container.dispose);

      await container.read(managerOpenIncidentTicketsProvider.future);
      await container.read(managerClosedIncidentTicketsProvider.future);
      await container.read(assignedToMeIncidentTicketsProvider.future);
      await container.read(myOpenIncidentTicketsProvider.future);
      await container.read(adminAllIncidentTicketsProvider.future);

      expect(repository.managerActiveCalls, 1);
      expect(repository.managerClosedCalls, 1);
      expect(repository.assignedUserIds, ['agent-1']);
      expect(repository.myActiveEmails, isEmpty);
      expect(repository.adminAllCalls, 0);
    });

    test('ADMIN uses owner-scoped self-service queues, not raw global data',
        () async {
      final repository = _RecordingIncidentRepository();
      final container = _container(
        role: IncidentRole.admin,
        repository: repository,
      );
      addTearDown(container.dispose);

      await container.read(adminAllIncidentTicketsProvider.future);
      await container.read(managerOpenIncidentTicketsProvider.future);
      await container.read(myOpenIncidentTicketsProvider.future);
      await container.read(myClosedAndArchivedIncidentTicketsProvider.future);

      expect(repository.adminAllCalls, 0);
      expect(repository.managerActiveCalls, 0);
      expect(repository.myActiveEmails, ['agent@arptc.cd']);
      expect(repository.myHistoryEmails, ['agent@arptc.cd']);
    });

    test('NONE does not open a protected repository subscription', () async {
      final repository = _RecordingIncidentRepository();
      final container = _container(
        role: IncidentRole.none,
        repository: repository,
      );
      addTearDown(container.dispose);

      await container.read(myOpenIncidentTicketsProvider.future);
      await container.read(managerOpenIncidentTicketsProvider.future);
      await container.read(adminAllIncidentTicketsProvider.future);

      expect(repository.totalCalls, 0);
    });
  });

  group('incident ownership policy', () {
    test('user dashboard includes creator or affected-user records only', () {
      final stats = IncidentDashboardAggregator.buildUserStats(
        [
          _ticket(id: 'created', createdByUserId: 'agent-1'),
          _ticket(id: 'affected', affectedUserId: 'agent-1'),
          _ticket(id: 'other', affectedUserId: 'agent-2'),
          _ticket(
            id: 'deleted',
            createdByUserId: 'agent-1',
            isDeleted: true,
          ),
          _ticket(
            id: 'closed',
            createdByUserId: 'agent-1',
            lifecycleState: IncidentLifecycleState.closed.value,
          ),
        ],
        'agent-1',
      );

      expect(
        stats.activeTicketQueue.map((ticket) => ticket.id).toSet(),
        {'created', 'affected'},
      );
      expect(stats.totalOpenCount, 2);
    });
  });
}

ProviderContainer _container({
  required IncidentRole role,
  required _RecordingIncidentRepository repository,
}) {
  return ProviderContainer(
    overrides: [
      authorizedSessionProvider.overrideWithValue(
        AuthorizedSessionState.authenticated(_authorizedSession(role)),
      ),
      currentIncidentUserProvider.overrideWith(
        (ref) => AsyncValue.data(
          IncidentUser(
            id: 'agent-1',
            displayName: 'Test Agent',
            email: 'agent@arptc.cd',
            departmentId: 'department-1',
            departmentName: 'DSI',
            serviceId: 'service-1',
            serviceName: 'Support',
            matricule: 'A-001',
            role: role,
          ),
        ),
      ),
      currentUserIncidentRoleProvider.overrideWith(
        (ref) => AsyncValue.data(role),
      ),
      incidentRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

AuthorizedSession _authorizedSession(IncidentRole role) {
  return AuthorizedSession(
    sessionKey: 'agent-1|agent@arptc.cd',
    userId: 'agent-1',
    email: 'agent@arptc.cd',
    displayName: 'Test Agent',
    profile: <String, Object?>{
      'id': 'agent-1',
      'email': 'agent@arptc.cd',
      'isActive': true,
      'modulePermissions': <String, String>{'ticketing': role.value},
    },
    modulePermissions: <String, String>{'ticketing': role.value},
  );
}

class _RecordingIncidentRepository implements IncidentRepository {
  final List<String> myActiveEmails = [];
  final List<String> myHistoryEmails = [];
  final List<String> assignedUserIds = [];
  int managerActiveCalls = 0;
  int managerClosedCalls = 0;
  int adminAllCalls = 0;

  int get totalCalls =>
      myActiveEmails.length +
      myHistoryEmails.length +
      assignedUserIds.length +
      managerActiveCalls +
      managerClosedCalls +
      adminAllCalls;

  @override
  Stream<List<IncidentTicket>> watchMyActiveTickets(String userEmail) {
    myActiveEmails.add(userEmail);
    return Stream.value(const []);
  }

  @override
  Stream<List<IncidentTicket>> watchMyClosedAndArchivedTickets(
    String userEmail,
  ) {
    myHistoryEmails.add(userEmail);
    return Stream.value(const []);
  }

  @override
  Stream<List<IncidentTicket>> watchAllActiveTicketsForManagers() {
    managerActiveCalls += 1;
    return Stream.value(const []);
  }

  @override
  Stream<List<IncidentTicket>> watchAllClosedTicketsForManagers() {
    managerClosedCalls += 1;
    return Stream.value(const []);
  }

  @override
  Stream<List<IncidentTicket>> watchAssignedToMeTickets(String userId) {
    assignedUserIds.add(userId);
    return Stream.value(const []);
  }

  @override
  Stream<List<IncidentTicket>> watchAllTicketsForAdmin() {
    adminAllCalls += 1;
    return Stream.value(const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

IncidentTicket _ticket({
  required String id,
  String createdByUserId = '',
  String affectedUserId = '',
  String lifecycleState = 'active',
  bool isDeleted = false,
}) {
  return IncidentTicket.empty().copyWith(
    id: id,
    title: id,
    createdByUserId: createdByUserId,
    affectedUserId: affectedUserId,
    lifecycleState: lifecycleState,
    isDeleted: isDeleted,
    createdAt: DateTime(2026, 7, 1),
  );
}
