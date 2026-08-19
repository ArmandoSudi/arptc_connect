import 'package:arptc_connect/modules/incident_management/application/incident_dashboard_aggregator.dart';
import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/incident_management/data/incident_actor.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_dashboard_stats.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_audit_log.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_category.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_comment.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_resolution_code.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_user.dart';
import 'package:arptc_connect/modules/incident_management/domain/it_service.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserIncidentRoleProvider = Provider<AsyncValue<IncidentRole>>(
  (ref) => ref.watch(currentIncidentUserProvider).whenData((user) => user.role),
);

final currentIncidentUserProvider = Provider<AsyncValue<IncidentUser>>((ref) {
  final appSession = ref.watch(authorizedSessionProvider);
  final session = appSession.session;
  if (session == null) {
    if (appSession.status == AuthenticationStatus.initializing ||
        appSession.status == AuthenticationStatus.profileLoading) {
      return const AsyncValue.loading();
    }
    return const AsyncValue.data(_emptyIncidentUser);
  }

  final profile = Map<String, dynamic>.from(session.profile);
  final displayName = _displayNameFromProfile(profile);
  return AsyncValue.data(
    IncidentUser(
      id: session.userId,
      displayName: displayName.isNotEmpty ? displayName : 'Agent',
      email: session.email,
      departmentId: _string(profile['departmentId']),
      departmentName: _string(profile['departmentName']),
      serviceId: _string(profile['serviceId']),
      serviceName: _string(profile['serviceName']),
      matricule: _string(profile['matricule']),
      role: _roleFromProfile(profile),
    ),
  );
});

final currentIncidentActorProvider = Provider<AsyncValue<IncidentActor>>((ref) {
  final userAsync = ref.watch(currentIncidentUserProvider);
  return userAsync.whenData((user) {
    return IncidentActor(
      userId: user.id,
      name: user.displayName,
      email: user.email,
      role: user.role,
    );
  });
});

final myOpenIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final user = ref.watch(currentIncidentUserProvider).valueOrNull;
  if (sessionKey == null ||
      user == null ||
      !_isSelfServiceRole(user.role) ||
      user.email.isEmpty) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref.read(incidentRepositoryProvider).watchMyActiveTickets(user.email);
});

final myClosedAndArchivedIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final user = ref.watch(currentIncidentUserProvider).valueOrNull;
  if (sessionKey == null ||
      user == null ||
      !_isSelfServiceRole(user.role) ||
      user.email.isEmpty) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref
      .read(incidentRepositoryProvider)
      .watchMyClosedAndArchivedTickets(user.email);
});

final managerOpenIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || role != IncidentRole.manager) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref
      .read(incidentRepositoryProvider)
      .watchAllActiveTicketsForManagers();
});

final managerClosedIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || role != IncidentRole.manager) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref
      .read(incidentRepositoryProvider)
      .watchAllClosedTicketsForManagers();
});

final assignedToMeIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final user = ref.watch(currentIncidentUserProvider).valueOrNull;
  if (sessionKey == null ||
      user == null ||
      user.role != IncidentRole.manager ||
      user.id.isEmpty) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref.read(incidentRepositoryProvider).watchAssignedToMeTickets(user.id);
});

final adminAllIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || role != IncidentRole.admin) {
    return Stream.value(const <IncidentTicket>[]);
  }
  // Organisation-wide ADMIN data is served only by trusted report snapshots.
  // The legacy raw-ticket stream remains intentionally disconnected.
  return Stream.value(const <IncidentTicket>[]);
});

final incidentCategoriesProvider =
    StreamProvider<List<IncidentCategory>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || !_hasIncidentAccess(role)) {
    return Stream.value(const <IncidentCategory>[]);
  }
  return ref.read(incidentRepositoryProvider).watchCategories();
});

final managedIncidentCategoriesProvider =
    StreamProvider<List<IncidentCategory>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || role != IncidentRole.manager) {
    return Stream.value(const <IncidentCategory>[]);
  }
  return ref.read(incidentRepositoryProvider).watchAllCategoriesForManagement();
});

final itServicesProvider = StreamProvider<List<ItService>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || !_hasIncidentAccess(role)) {
    return Stream.value(const <ItService>[]);
  }
  return ref.read(incidentRepositoryProvider).watchItServices();
});

final managedItServicesProvider = StreamProvider<List<ItService>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || role != IncidentRole.manager) {
    return Stream.value(const <ItService>[]);
  }
  return ref.read(incidentRepositoryProvider).watchAllItServicesForManagement();
});

final incidentResolutionCodesProvider =
    StreamProvider<List<IncidentResolutionCode>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || !_hasIncidentAccess(role)) {
    return Stream.value(const <IncidentResolutionCode>[]);
  }
  return ref.read(incidentRepositoryProvider).watchResolutionCodes();
});

final managedIncidentResolutionCodesProvider =
    StreamProvider<List<IncidentResolutionCode>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || role != IncidentRole.manager) {
    return Stream.value(const <IncidentResolutionCode>[]);
  }
  return ref
      .read(incidentRepositoryProvider)
      .watchAllResolutionCodesForManagement();
});

final itStaffUsersProvider = StreamProvider<List<IncidentUser>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || role != IncidentRole.manager) {
    return Stream.value(const <IncidentUser>[]);
  }
  return ref.read(incidentRepositoryProvider).watchItStaffUsers();
});

final incidentAgentsProvider = StreamProvider<List<IncidentUser>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  final profile = ref.watch(authorizedAgentProfileProvider).valueOrNull;
  final organizationId = (profile?['organizationId'] ?? '').toString().trim();
  if (sessionKey == null || role != IncidentRole.manager) {
    return Stream.value(const <IncidentUser>[]);
  }
  if (organizationId.isEmpty) return Stream.value(const <IncidentUser>[]);
  return ref.read(incidentRepositoryProvider).watchAgents(organizationId);
});

final incidentTicketProvider =
    StreamProvider.family<IncidentTicket?, String>((ref, ticketId) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || !_hasIncidentAccess(role)) {
    return Stream.value(null);
  }
  return ref.read(incidentRepositoryProvider).watchTicketById(ticketId);
});

final incidentCommentsProvider =
    StreamProvider.family<List<IncidentComment>, String>((ref, ticketId) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || !_hasIncidentAccess(role)) {
    return Stream.value(const <IncidentComment>[]);
  }
  return ref.read(incidentRepositoryProvider).watchComments(
        ticketId,
        includeInternal: role == IncidentRole.manager,
      );
});

final incidentAuditLogsProvider =
    StreamProvider.family<List<IncidentAuditLog>, String>((ref, ticketId) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final role = ref.watch(currentUserIncidentRoleProvider).valueOrNull;
  if (sessionKey == null || !_hasIncidentAccess(role)) {
    return Stream.value(const <IncidentAuditLog>[]);
  }
  return ref.read(incidentRepositoryProvider).watchAuditLogs(ticketId);
});

final managerIncidentDashboardStatsProvider =
    Provider<AsyncValue<IncidentDashboardStats>>((ref) {
  final currentUserAsync = ref.watch(currentIncidentUserProvider);
  final activeTicketsAsync = ref.watch(managerOpenIncidentTicketsProvider);
  final closedTicketsAsync = ref.watch(managerClosedIncidentTicketsProvider);

  return currentUserAsync.when(
    data: (currentUser) {
      return activeTicketsAsync.when(
        data: (activeTickets) {
          return closedTicketsAsync.when(
            data: (closedTickets) {
              return AsyncValue.data(
                IncidentDashboardAggregator.buildManagerStats(
                  [...activeTickets, ...closedTickets],
                  currentUser.id,
                ),
              );
            },
            loading: () => const AsyncValue.loading(),
            error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final adminIncidentDashboardStatsProvider =
    Provider<AsyncValue<IncidentDashboardStats>>((ref) {
  final ticketsAsync = ref.watch(adminAllIncidentTicketsProvider);

  return ticketsAsync.when(
    data: (tickets) => AsyncValue.data(
      IncidentDashboardAggregator.buildAdminStats(tickets),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

IncidentRole _roleFromProfile(Map<String, dynamic> profile) {
  final rawPermissions = profile['modulePermissions'];
  final permissions = Modules.normalizePermissions(
    rawPermissions is Map<String, dynamic>
        ? rawPermissions
        : rawPermissions is Map
            ? Map<String, dynamic>.from(rawPermissions)
            : null,
    includeDefaultModules: false,
  );

  final roleValue = permissions['support'] ??
      permissions['ticketing'] ??
      permissions['incident'] ??
      permissions['incidents'] ??
      permissions['incidentmanagement'] ??
      permissions['incident_management'] ??
      permissions['ticket'] ??
      permissions['tickets'] ??
      ModuleAccessRole.none.value;

  return IncidentRole.fromValue(roleValue);
}

String _displayNameFromProfile(Map<String, dynamic> profile) {
  final pieces = [
    _string(profile['firstName']),
    _string(profile['name']),
    _string(profile['postName']),
  ].where((piece) => piece.isNotEmpty).toList();

  if (pieces.isNotEmpty) {
    return pieces.join(' ');
  }
  return _string(profile['fullName']);
}

String _string(dynamic value) => value?.toString().trim() ?? '';

const _emptyIncidentUser = IncidentUser(
  id: '',
  displayName: '',
  email: '',
  departmentId: '',
  departmentName: '',
  serviceId: '',
  serviceName: '',
  matricule: '',
  role: IncidentRole.none,
);

bool _hasIncidentAccess(IncidentRole? role) {
  return role == IncidentRole.user ||
      role == IncidentRole.manager ||
      role == IncidentRole.admin;
}

bool _isSelfServiceRole(IncidentRole role) {
  return role == IncidentRole.user || role == IncidentRole.admin;
}
