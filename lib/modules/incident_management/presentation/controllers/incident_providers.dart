import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/incident_management/application/incident_dashboard_aggregator.dart';
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
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserIncidentRoleProvider =
    Provider<AsyncValue<IncidentRole>>((ref) {
  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData(_roleFromProfile);
});

final currentIncidentUserProvider = Provider<AsyncValue<IncidentUser>>((ref) {
  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData((profile) {
    final authUser = ref.read(firebaseAuthProvider).currentUser;
    final displayName = _displayNameFromProfile(profile);
    final profileId = _string(profile['id']);
    return IncidentUser(
      id: profileId.isNotEmpty ? profileId : authUser?.uid ?? '',
      displayName: displayName.isNotEmpty ? displayName : 'Agent',
      email: _string(profile['email']),
      departmentId: _string(profile['departmentId']),
      departmentName: _string(profile['departmentName']),
      serviceId: _string(profile['serviceId']),
      serviceName: _string(profile['serviceName']),
      matricule: _string(profile['matricule']),
      role: _roleFromProfile(profile),
    );
  });
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
  final user = ref.watch(currentIncidentUserProvider).valueOrNull;
  if (user == null || user.email.isEmpty) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref.read(incidentRepositoryProvider).watchMyActiveTickets(user.email);
});

final myClosedAndArchivedIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final user = ref.watch(currentIncidentUserProvider).valueOrNull;
  if (user == null || user.email.isEmpty) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref
      .read(incidentRepositoryProvider)
      .watchMyClosedAndArchivedTickets(user.email);
});

final managerOpenIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  return ref
      .read(incidentRepositoryProvider)
      .watchAllActiveTicketsForManagers();
});

final managerClosedIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  return ref
      .read(incidentRepositoryProvider)
      .watchAllClosedTicketsForManagers();
});

final assignedToMeIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  final user = ref.watch(currentIncidentUserProvider).valueOrNull;
  if (user == null || user.id.isEmpty) {
    return Stream.value(const <IncidentTicket>[]);
  }
  return ref.read(incidentRepositoryProvider).watchAssignedToMeTickets(user.id);
});

final adminAllIncidentTicketsProvider =
    StreamProvider<List<IncidentTicket>>((ref) {
  return ref.read(incidentRepositoryProvider).watchAllTicketsForAdmin();
});

final incidentCategoriesProvider =
    StreamProvider<List<IncidentCategory>>((ref) {
  return ref.read(incidentRepositoryProvider).watchCategories();
});

final managedIncidentCategoriesProvider =
    StreamProvider<List<IncidentCategory>>((ref) {
  return ref.read(incidentRepositoryProvider).watchAllCategoriesForManagement();
});

final itServicesProvider = StreamProvider<List<ItService>>((ref) {
  return ref.read(incidentRepositoryProvider).watchItServices();
});

final managedItServicesProvider = StreamProvider<List<ItService>>((ref) {
  return ref.read(incidentRepositoryProvider).watchAllItServicesForManagement();
});

final incidentResolutionCodesProvider =
    StreamProvider<List<IncidentResolutionCode>>((ref) {
  return ref.read(incidentRepositoryProvider).watchResolutionCodes();
});

final managedIncidentResolutionCodesProvider =
    StreamProvider<List<IncidentResolutionCode>>((ref) {
  return ref
      .read(incidentRepositoryProvider)
      .watchAllResolutionCodesForManagement();
});

final itStaffUsersProvider = StreamProvider<List<IncidentUser>>((ref) {
  return ref.read(incidentRepositoryProvider).watchItStaffUsers();
});

final incidentAgentsProvider = StreamProvider<List<IncidentUser>>((ref) {
  return ref.read(incidentRepositoryProvider).watchAgents();
});

final incidentTicketProvider =
    StreamProvider.family<IncidentTicket?, String>((ref, ticketId) {
  return ref.read(incidentRepositoryProvider).watchTicketById(ticketId);
});

final incidentCommentsProvider =
    StreamProvider.family<List<IncidentComment>, String>((ref, ticketId) {
  return ref.read(incidentRepositoryProvider).watchComments(ticketId);
});

final incidentAuditLogsProvider =
    StreamProvider.family<List<IncidentAuditLog>, String>((ref, ticketId) {
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
