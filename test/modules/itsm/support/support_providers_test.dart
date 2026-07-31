import 'dart:async';

import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:arptc_connect/modules/itsm/support/application/support_providers.dart';
import 'package:arptc_connect/modules/itsm/support/data/service_request_repository.dart';
import 'package:arptc_connect/modules/itsm/support/domain/service_request.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agent search returns only active name/email/matricule matches',
      () async {
    final container = ProviderContainer(
      overrides: [
        umAgentsProvider.overrideWith((ref) async => [
              _agent(
                id: 'armando',
                name: 'Armando Sudi',
                email: 'armando@example.com',
                matricule: 'A-100',
              ),
              _agent(
                id: 'inactive',
                name: 'Armando Inactive',
                email: 'inactive@example.com',
                matricule: 'A-200',
                active: false,
              ),
              _agent(
                id: 'other',
                name: 'Other Agent',
                email: 'other@example.com',
                matricule: 'B-100',
              ),
            ]),
      ],
    );
    addTearDown(container.dispose);

    await container.read(umAgentsProvider.future);
    final result = container.read(
      serviceRequestAgentSearchProvider(
        const ServiceRequestAgentSearch('A-1'),
      ),
    );

    expect(result.requireValue.map((agent) => agent.id), ['armando']);
  });

  test('live request provider resubscribes for the new authenticated user',
      () async {
    final sessions = StreamController<ItsmSession?>();
    final repository = _RecordingServiceRequestRepository();
    final container = ProviderContainer(
      overrides: [
        itsmSessionProvider.overrideWith((ref) => sessions.stream),
        serviceRequestRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
    final request = ServiceRequestFirstPageRequest(
      query: ServiceRequestQuery(scope: ServiceRequestScope.myActive),
      limit: 10,
    );
    final subscription = container.listen(
      serviceRequestFirstPageProvider(request),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    sessions.add(_session('user-1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sessions.add(_session('user-2'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      repository.principals.map((principal) => principal.userId),
      containsAllInOrder(['user-1', 'user-2']),
    );
  });
}

ItsmSession _session(String userId) => ItsmSession(
      sessionKey: '$userId|$userId@example.com',
      userId: userId,
      email: '$userId@example.com',
      displayName: userId,
      role: ItsmRole.user,
    );

class _RecordingServiceRequestRepository implements ServiceRequestRepository {
  final List<ItsmQueryPrincipal> principals = [];

  @override
  Future<PageResult<ServiceRequest>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ServiceRequestQuery query,
    required PageRequest page,
  }) async {
    principals.add(principal);
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Stream<ServiceRequest?> watchById({
    required ItsmQueryPrincipal principal,
    required String id,
  }) {
    principals.add(principal);
    return Stream.value(null);
  }

  @override
  Stream<ServiceRequestDetail?> watchDetail({
    required ItsmQueryPrincipal principal,
    required String id,
    int childLimit = 100,
  }) {
    principals.add(principal);
    return Stream.value(null);
  }

  @override
  Stream<List<ServiceRequest>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ServiceRequestQuery query,
    required int limit,
  }) {
    principals.add(principal);
    return Stream<List<ServiceRequest>>.multi(
      (controller) => controller.add(const []),
    );
  }
}

UserManagementAgent _agent({
  required String id,
  required String name,
  required String email,
  required String matricule,
  bool active = true,
}) {
  final parts = name.split(' ');
  return UserManagementAgent(
    id: id,
    firstName: parts.first,
    name: parts.skip(1).join(' '),
    postName: '',
    matricule: matricule,
    email: email,
    emailLower: email.toLowerCase(),
    position: 'BUREAU_ATTACHE',
    departmentId: 'department-1',
    serviceId: 'service-1',
    bureauId: 'bureau-1',
    isActive: active,
    modulePermissions: const {'ticketing': 'USER'},
  );
}
