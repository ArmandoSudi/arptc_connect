import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_audit_event.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_assignment.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_access.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/domain/unplaced_agent_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_command_controller.dart';
import 'package:arptc_connect/modules/usermanagement/application/organization_hierarchy_loader.dart';

final userManagementAccessPolicyProvider =
    Provider<UserManagementAccessPolicy>((ref) {
  final profile = ref.watch(authorizedAgentProfileProvider).valueOrNull;
  return UserManagementAccessPolicy.fromProfile(
    profile ?? const <String, dynamic>{},
  );
});

final umOrganizationCommandControllerProvider = StateNotifierProvider<
    OrganizationCommandController, OrganizationCommandState>((ref) {
  final policy = ref.watch(userManagementAccessPolicyProvider);
  return OrganizationCommandController(
    canManage: policy.canManageOrganization,
  );
});

final umOrganizationsProvider = StreamProvider<List<Organization>>((ref) {
  final policy = ref.watch(userManagementAccessPolicyProvider);
  final repository = ref.read(userManagementRepositoryProvider);
  if (policy.canReadPrivateProfiles) return repository.watchOrganizations();
  final profile = ref.watch(authorizedAgentProfileProvider).valueOrNull;
  final organizationId = (profile?['organizationId'] ?? '').toString().trim();
  return repository.watchOrganizationDirectoryById(organizationId);
});

final umFilteredOrganizationsProvider = StreamProvider.autoDispose
    .family<List<Organization>, OrganizationListQuery>((ref, query) {
  final policy = ref.watch(userManagementAccessPolicyProvider);
  if (!policy.canReadPrivateProfiles) {
    final profile = ref.watch(authorizedAgentProfileProvider).valueOrNull;
    final organizationId = (profile?['organizationId'] ?? '').toString().trim();
    return ref
        .read(userManagementRepositoryProvider)
        .watchOrganizationDirectoryById(organizationId);
  }
  return ref
      .read(userManagementRepositoryProvider)
      .watchOrganizationsQuery(query);
});

final umSelectedOrganizationIdProvider = StateProvider<String>((ref) => '');

final umEffectiveOrganizationIdProvider = Provider<String>((ref) {
  final selected = ref.watch(umSelectedOrganizationIdProvider).trim();
  if (selected.isNotEmpty) return selected;
  final profile = ref.watch(authorizedAgentProfileProvider).valueOrNull;
  return (profile?['organizationId'] ?? '').toString().trim();
});

final umOrganizationUnitsProvider =
    StreamProvider.family<List<OrganizationUnit>, String>(
        (ref, organizationId) {
  if (organizationId.trim().isEmpty) {
    return Stream.value(const <OrganizationUnit>[]);
  }
  if (!ref.watch(userManagementAccessPolicyProvider).canReadPrivateProfiles) {
    return Stream.value(const <OrganizationUnit>[]);
  }
  return ref.read(userManagementRepositoryProvider).watchOrganizationUnits(
        organizationId: organizationId,
      );
});

final umCompleteOrganizationHierarchyProvider = FutureProvider.autoDispose
    .family<List<OrganizationUnit>, String>((ref, organizationId) {
  if (organizationId.trim().isEmpty ||
      !ref.watch(userManagementAccessPolicyProvider).canReadPrivateProfiles) {
    return const <OrganizationUnit>[];
  }
  final repository = ref.read(userManagementRepositoryProvider);
  return OrganizationHierarchyLoader(
    fetchPage: repository.fetchOrganizationUnitsPage,
  ).load(organizationId);
});

final umOrganizationUnitDetailsProvider = StreamProvider.autoDispose
    .family<OrganizationUnit, OrganizationUnitIdentity>((ref, identity) {
  if (!identity.isValid ||
      !ref.watch(userManagementAccessPolicyProvider).canReadPrivateProfiles) {
    return Stream.error(StateError('Organization unit access is unavailable.'));
  }
  return ref
      .read(userManagementRepositoryProvider)
      .watchOrganizationUnitById(identity);
});

final umFilteredOrganizationUnitsProvider = StreamProvider.autoDispose
    .family<List<OrganizationUnit>, OrganizationUnitListQuery>((ref, query) {
  if (query.organizationId.trim().isEmpty) {
    return Stream.value(const <OrganizationUnit>[]);
  }
  if (!ref.watch(userManagementAccessPolicyProvider).canReadPrivateProfiles) {
    return Stream.value(const <OrganizationUnit>[]);
  }
  return ref
      .read(userManagementRepositoryProvider)
      .watchOrganizationUnitsQuery(query);
});

final umAgentDirectorySearchProvider = StateProvider<String>((ref) => '');

final umAgentDirectoryProvider =
    StreamProvider.family<List<AgentDirectoryEntry>, String>(
        (ref, organizationId) {
  if (organizationId.trim().isEmpty) {
    return Stream.value(const <AgentDirectoryEntry>[]);
  }
  final search = ref.watch(umAgentDirectorySearchProvider);
  return ref.read(userManagementRepositoryProvider).watchAgentDirectory(
        organizationId: organizationId,
        search: search,
      );
});

final umFilteredAgentDirectoryProvider = StreamProvider.autoDispose
    .family<List<AgentDirectoryEntry>, AgentDirectoryListQuery>((ref, query) {
  if (query.organizationId.trim().isEmpty) {
    return Stream.value(const <AgentDirectoryEntry>[]);
  }
  return ref
      .read(userManagementRepositoryProvider)
      .watchAgentDirectoryQuery(query);
});

final umCurrentOrganizationAgentDirectoryProvider =
    StreamProvider<List<AgentDirectoryEntry>>((ref) {
  final profile = ref.watch(authorizedAgentProfileProvider).valueOrNull;
  final organizationId = (profile?['organizationId'] ?? '').toString().trim();
  if (organizationId.isEmpty) {
    return Stream.value(const <AgentDirectoryEntry>[]);
  }
  return ref.read(userManagementRepositoryProvider).watchAgentDirectory(
        organizationId: organizationId,
      );
});

final umUnplacedAgentsProvider =
    FutureProvider.autoDispose<UnplacedAgentPage>((ref) {
  final policy = ref.watch(userManagementAccessPolicyProvider);
  if (!policy.canManageOrganization) {
    return const UnplacedAgentPage(
      items: [],
      nextCursor: null,
      scannedCount: 0,
    );
  }
  return ref.read(userManagementRepositoryProvider).fetchUnplacedAgentsPage();
});

final umAgentOrganizationAssignmentsProvider = StreamProvider.family<
    List<OrganizationAssignment>, OrganizationAssignmentQuery>((ref, query) {
  if (!query.isValid || !query.isAgentQuery) {
    return Stream.value(const <OrganizationAssignment>[]);
  }
  return ref
      .read(userManagementRepositoryProvider)
      .watchAgentOrganizationAssignments(
        organizationId: query.organizationId,
        agentId: query.agentId,
      );
});

final umUnitOrganizationAssignmentsProvider = StreamProvider.family<
    List<OrganizationAssignment>, OrganizationAssignmentQuery>((ref, query) {
  if (!query.isValid || query.isAgentQuery) {
    return Stream.value(const <OrganizationAssignment>[]);
  }
  return ref
      .read(userManagementRepositoryProvider)
      .watchUnitOrganizationAssignments(
        organizationId: query.organizationId,
        unitId: query.unitId,
      );
});

final umOrganizationAuditEventsProvider = StreamProvider.autoDispose
    .family<List<OrganizationAuditEvent>, OrganizationAuditQuery>((ref, query) {
  if (!query.isValid ||
      !ref.watch(userManagementAccessPolicyProvider).canReadAudit) {
    return Stream.value(const <OrganizationAuditEvent>[]);
  }
  return ref
      .read(userManagementRepositoryProvider)
      .watchOrganizationAuditEvents(query);
});

final umModulesProvider = StreamProvider<List<UserManagementModule>>((ref) {
  return ref.read(userManagementRepositoryProvider).watchModules();
});
