import 'dart:developer';

import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_architecture_audit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_audit_event.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_assignment.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/unplaced_agent_summary.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserManagementRepository {
  UserManagementRepository(this.firestoreClient, this.firebaseFunctions);

  final FirestoreClient firestoreClient;
  final FirebaseFunctions firebaseFunctions;
  static const String _agentsPath = 'agents';
  static const String _modulesPath = 'modules';
  static const String _organizationsPath = 'organizations';
  static const String _organizationDirectoryPath = 'organizationDirectory';
  static const String _organizationUnitsPath = 'organizationUnits';
  static const String _organizationAssignmentsPath = 'organizationAssignments';
  static const String _organizationAuditEventsPath = 'organizationAuditEvents';
  static const String _agentDirectoryPath = 'agentDirectory';

  Stream<List<Organization>> watchOrganizations({
    int limit = 50,
    bool includeArchived = false,
  }) {
    return watchOrganizationsQuery(OrganizationListQuery(
      status: includeArchived
          ? OrganizationListStatusFilter.all
          : OrganizationListStatusFilter.current,
      limit: limit,
    ));
  }

  Stream<List<Organization>> watchOrganizationsQuery(
    OrganizationListQuery request,
  ) {
    final query = _organizationQuery(request).limit(request.limit);
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => Organization.fromMap(
                    document.data(),
                    id: document.id,
                  ))
              .toList(growable: false),
        );
  }

  Stream<List<Organization>> watchOrganizationById(String organizationId) {
    final normalizedId = organizationId.trim();
    if (normalizedId.isEmpty) {
      return Stream.value(const <Organization>[]);
    }
    return firestoreClient.firestore
        .collection(_organizationsPath)
        .doc(normalizedId)
        .snapshots()
        .map((document) {
      final data = document.data();
      if (!document.exists || data == null) return const <Organization>[];
      return [Organization.fromMap(data, id: document.id)];
    });
  }

  Stream<List<Organization>> watchOrganizationDirectoryById(
    String organizationId,
  ) {
    final normalizedId = organizationId.trim();
    if (normalizedId.isEmpty) {
      return Stream.value(const <Organization>[]);
    }
    return firestoreClient.firestore
        .collection(_organizationDirectoryPath)
        .doc(normalizedId)
        .snapshots()
        .map((document) {
      final data = document.data();
      if (!document.exists || data == null) return const <Organization>[];
      return [Organization.fromMap(data, id: document.id)];
    });
  }

  Stream<List<OrganizationUnit>> watchOrganizationUnits({
    required String organizationId,
    int limit = 100,
    bool includeArchived = false,
  }) {
    return watchOrganizationUnitsQuery(OrganizationUnitListQuery(
      organizationId: organizationId,
      status: includeArchived
          ? OrganizationListStatusFilter.all
          : OrganizationListStatusFilter.current,
      limit: limit,
    ));
  }

  Stream<List<OrganizationUnit>> watchOrganizationUnitsQuery(
    OrganizationUnitListQuery request,
  ) {
    if (request.organizationId.trim().isEmpty) {
      return Stream.value(const <OrganizationUnit>[]);
    }
    final query = _organizationUnitQuery(request).limit(request.limit);
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => OrganizationUnit.fromMap(
                    document.data(),
                    id: document.id,
                  ))
              .toList(growable: false),
        );
  }

  Stream<List<AgentDirectoryEntry>> watchAgentDirectory({
    required String organizationId,
    String search = '',
    int limit = 50,
    bool activeOnly = true,
  }) {
    return watchAgentDirectoryQuery(AgentDirectoryListQuery(
      organizationId: organizationId,
      search: search,
      status: activeOnly
          ? AgentDirectoryStatusFilter.active
          : AgentDirectoryStatusFilter.all,
      limit: limit,
    ));
  }

  Stream<List<AgentDirectoryEntry>> watchAgentDirectoryQuery(
    AgentDirectoryListQuery request,
  ) {
    if (request.organizationId.trim().isEmpty) {
      return Stream.value(const <AgentDirectoryEntry>[]);
    }
    final query = _agentDirectoryQuery(request).limit(request.limit);
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => AgentDirectoryEntry.fromMap(
                    document.data(),
                    id: document.id,
                  ))
              .toList(growable: false),
        );
  }

  Stream<OrganizationUnit> watchOrganizationUnitById(
    OrganizationUnitIdentity identity,
  ) {
    if (!identity.isValid) {
      return Stream.error(
        ArgumentError('A valid organization unit is required.'),
      );
    }
    final organizationId = identity.organizationId.trim();
    return firestoreClient.firestore
        .collection(_organizationUnitsPath)
        .doc(identity.unitId.trim())
        .snapshots()
        .map((document) {
      final data = document.data();
      if (!document.exists || data == null) {
        throw StateError('The requested organization unit was not found.');
      }
      final unit = OrganizationUnit.fromMap(data, id: document.id);
      if (unit.organizationId != organizationId) {
        throw StateError(
          'The requested organization unit belongs to another organization.',
        );
      }
      return unit;
    });
  }

  Future<OrganizationPage<Organization>> fetchOrganizationsPage({
    required OrganizationListQuery query,
    required OrganizationPageRequest page,
  }) async {
    _validateLimit(page.limit);
    final snapshot = await _withPageCursor(
      _organizationQuery(
        query,
        includeSearchStart: !_hasPageCursor(page),
      ),
      page,
    ).limit(page.limit).get();
    final items = snapshot.docs
        .map((document) => Organization.fromMap(
              document.data(),
              id: document.id,
            ))
        .toList(growable: false);
    return _pageFromDocuments(items, snapshot.docs, page.limit, 'nameLower');
  }

  Future<OrganizationPage<OrganizationUnit>> fetchOrganizationUnitsPage({
    required OrganizationUnitListQuery query,
    required OrganizationPageRequest page,
  }) async {
    _validateLimit(page.limit);
    final snapshot = await _withPageCursor(
      _organizationUnitQuery(
        query,
        includeSearchStart: !_hasPageCursor(page),
      ),
      page,
    ).limit(page.limit).get();
    final items = snapshot.docs
        .map((document) => OrganizationUnit.fromMap(
              document.data(),
              id: document.id,
            ))
        .toList(growable: false);
    return _pageFromDocuments(items, snapshot.docs, page.limit, 'nameLower');
  }

  Future<OrganizationPage<AgentDirectoryEntry>> fetchAgentDirectoryPage({
    required AgentDirectoryListQuery query,
    required OrganizationPageRequest page,
  }) async {
    _validateLimit(page.limit);
    final snapshot = await _withPageCursor(
      _agentDirectoryQuery(
        query,
        includeSearchStart: !_hasPageCursor(page),
      ),
      page,
    ).limit(page.limit).get();
    final items = snapshot.docs
        .map((document) => AgentDirectoryEntry.fromMap(
              document.data(),
              id: document.id,
            ))
        .toList(growable: false);
    return _pageFromDocuments(
      items,
      snapshot.docs,
      page.limit,
      'displayNameLower',
    );
  }

  Stream<UserManagementAgent> watchAgentById(String agentId) {
    final normalizedId = agentId.trim();
    if (normalizedId.isEmpty) {
      return Stream.error(ArgumentError.value(agentId, 'agentId'));
    }
    return firestoreClient.firestore
        .collection(_agentsPath)
        .doc(normalizedId)
        .snapshots()
        .map((document) {
      final data = document.data();
      if (!document.exists || data == null) {
        throw StateError('The requested agent profile was not found.');
      }
      return UserManagementAgent.fromMap(data, id: document.id);
    });
  }

  Stream<List<OrganizationAssignment>> watchAgentOrganizationAssignments({
    required String organizationId,
    required String agentId,
    int limit = 50,
  }) {
    return watchOrganizationAssignments(OrganizationAssignmentQuery.agent(
      organizationId: organizationId,
      agentId: agentId,
      limit: limit,
    ));
  }

  Stream<List<OrganizationAssignment>> watchUnitOrganizationAssignments({
    required String organizationId,
    required String unitId,
    int limit = 50,
  }) {
    return watchOrganizationAssignments(OrganizationAssignmentQuery.unit(
      organizationId: organizationId,
      unitId: unitId,
      limit: limit,
    ));
  }

  Stream<List<OrganizationAssignment>> watchOrganizationAssignments(
    OrganizationAssignmentQuery request,
  ) {
    if (!request.isValid) {
      return Stream.value(const <OrganizationAssignment>[]);
    }
    return _organizationAssignmentQuery(request)
        .limit(request.limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => OrganizationAssignment.fromMap(
                    document.data(),
                    id: document.id,
                  ))
              .toList(growable: false),
        );
  }

  Future<OrganizationTimelinePage<OrganizationAssignment>>
      fetchOrganizationAssignmentsPage({
    required OrganizationAssignmentQuery query,
    required OrganizationTimelinePageRequest page,
  }) async {
    _validateLimit(page.limit);
    final snapshot = await _withTimelineCursor(
      _organizationAssignmentQuery(query),
      page,
    ).limit(page.limit).get();
    final items = snapshot.docs
        .map((document) => OrganizationAssignment.fromMap(
              document.data(),
              id: document.id,
            ))
        .toList(growable: false);
    return _timelinePageFromDocuments(
      items,
      snapshot.docs,
      page.limit,
      'startsAt',
    );
  }

  Stream<List<OrganizationAuditEvent>> watchOrganizationAuditEvents(
    OrganizationAuditQuery request,
  ) {
    if (!request.isValid) {
      return Stream.value(const <OrganizationAuditEvent>[]);
    }
    return _organizationAuditQuery(request)
        .limit(request.limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => OrganizationAuditEvent.fromMap(
                    document.data(),
                    id: document.id,
                  ))
              .toList(growable: false),
        );
  }

  Future<OrganizationTimelinePage<OrganizationAuditEvent>>
      fetchOrganizationAuditEventsPage({
    required OrganizationAuditQuery query,
    required OrganizationTimelinePageRequest page,
  }) async {
    _validateLimit(page.limit);
    final snapshot = await _withTimelineCursor(
      _organizationAuditQuery(query),
      page,
    ).limit(page.limit).get();
    final items = snapshot.docs
        .map((document) => OrganizationAuditEvent.fromMap(
              document.data(),
              id: document.id,
            ))
        .toList(growable: false);
    return _timelinePageFromDocuments(
      items,
      snapshot.docs,
      page.limit,
      'createdAt',
    );
  }

  Future<String> createOrganization({
    required String code,
    required String name,
    required String description,
  }) async {
    final result = await _callOrganizationCommand('createOrganization', {
      'code': code,
      'name': name,
      'description': description,
    });
    return (result['organizationId'] ?? '').toString();
  }

  Future<void> updateOrganization(Organization organization) async {
    await _callOrganizationCommand('updateOrganization', {
      ...organization.toCommandPayload(),
      'status': organization.status.value,
    });
  }

  Future<void> archiveOrganization({
    required String organizationId,
    required String reason,
  }) async {
    await _callOrganizationCommand('archiveOrganization', {
      'organizationId': organizationId,
      'reason': reason,
    });
  }

  Future<String> createOrganizationUnit({
    required String organizationId,
    required OrganizationUnitType type,
    required String code,
    required String name,
    required String description,
    String? parentUnitId,
  }) async {
    final result = await _callOrganizationCommand('createOrganizationUnit', {
      'organizationId': organizationId,
      'type': type.value,
      'code': code,
      'name': name,
      'description': description,
      'parentUnitId': parentUnitId,
    });
    return (result['organizationUnitId'] ?? '').toString();
  }

  Future<void> updateOrganizationUnit(OrganizationUnit unit) async {
    await _callOrganizationCommand('updateOrganizationUnit', {
      'organizationId': unit.organizationId,
      'organizationUnitId': unit.id,
      'code': unit.code,
      'name': unit.name,
      'description': unit.description,
      'status': unit.status.value,
    });
  }

  Future<void> moveOrganizationUnit({
    required String organizationId,
    required String unitId,
    required String parentUnitId,
    required String reason,
  }) async {
    await _callOrganizationCommand('moveOrganizationUnit', {
      'organizationId': organizationId,
      'organizationUnitId': unitId,
      'parentUnitId': parentUnitId,
      'reason': reason,
    });
  }

  Future<void> archiveOrganizationUnit({
    required String organizationId,
    required String unitId,
    required String reason,
  }) async {
    await _callOrganizationCommand('archiveOrganizationUnit', {
      'organizationId': organizationId,
      'organizationUnitId': unitId,
      'reason': reason,
    });
  }

  Future<void> assignAgentOrganization({
    required String agentId,
    required String organizationId,
    required String unitId,
    required DateTime startsAt,
    required String reason,
    required bool transfer,
    bool assignAsHead = false,
  }) async {
    await _callOrganizationCommand(
      transfer ? 'transferAgentOrganization' : 'assignAgentOrganization',
      {
        'agentId': agentId,
        'organizationId': organizationId,
        'organizationUnitId': unitId,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'reason': reason,
        'assignAsHead': assignAsHead,
      },
    );
  }

  Future<void> setOrganizationUnitHead({
    required String organizationId,
    required String unitId,
    required String agentId,
    required DateTime startsAt,
    DateTime? endsAt,
    required bool isActing,
    required String reason,
  }) async {
    await _callOrganizationCommand('setOrganizationUnitHead', {
      'organizationId': organizationId,
      'organizationUnitId': unitId,
      'agentId': agentId,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt?.toUtc().toIso8601String(),
      'isActing': isActing,
      'reason': reason,
    });
  }

  Future<void> endOrganizationUnitHead({
    required String organizationId,
    required String assignmentId,
    required String reason,
  }) async {
    await _callOrganizationCommand('endOrganizationUnitHead', {
      'organizationId': organizationId,
      'assignmentId': assignmentId,
      'reason': reason,
    });
  }

  Future<void> deactivateAgent({
    required String agentId,
    required String organizationId,
    required DateTime effectiveAt,
    required String reason,
  }) async {
    await _callOrganizationCommand('deactivateAgentAccount', {
      'agentId': agentId,
      'organizationId': organizationId,
      'effectiveAt': effectiveAt.toUtc().toIso8601String(),
      'reason': reason,
    });
  }

  Future<OrganizationArchitectureAuditReport> auditOrganizationArchitecture({
    required String organizationId,
    bool repair = false,
    String reason = '',
  }) async {
    final result = await _callOrganizationCommand(
      'auditOrganizationArchitecture',
      {
        'organizationId': organizationId,
        'limit': 100,
        'repair': repair,
        if (repair) 'reason': reason.trim(),
      },
    );
    return OrganizationArchitectureAuditReport.fromMap(result);
  }

  Future<UnplacedAgentPage> fetchUnplacedAgentsPage({
    int limit = 100,
    String? afterId,
  }) async {
    _validateLimit(limit);
    try {
      final callable = firebaseFunctions.httpsCallable('listUnplacedAgents');
      final result = await callable.call<Map<String, dynamic>>({
        'limit': limit,
        if (afterId?.trim().isNotEmpty == true) 'afterId': afterId!.trim(),
      });
      return UnplacedAgentPage.fromMap(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw OrganizationCommandException(
        code: error.code,
        message: error.message ?? 'Unable to load unplaced agents.',
      );
    }
  }

  Future<List<UnplacedAgentSummary>> fetchUnplacedAgents({
    int limit = 100,
    String? afterId,
  }) async =>
      (await fetchUnplacedAgentsPage(limit: limit, afterId: afterId)).items;

  Future<Map<String, dynamic>> _callOrganizationCommand(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    try {
      final callable = firebaseFunctions.httpsCallable(functionName);
      final commandId = firestoreClient.firestore
          .collection('organizationCommandReceipts')
          .doc()
          .id;
      final result = await callable.call<Map<String, dynamic>>({
        ...payload,
        'commandId': commandId,
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw OrganizationCommandException(
        code: error.code,
        message: error.message ?? 'Unable to complete the organization action.',
      );
    }
  }

  Future<String> createAgentAccount(
    UserManagementAgent agent, {
    DateTime? assignmentStartsAt,
    String assignmentReason = 'Initial organization placement',
    bool assignAsHead = false,
  }) async {
    try {
      final callable = firebaseFunctions.httpsCallable('createAgentAccount');
      final result = await callable.call<Map<String, dynamic>>(
        {
          'commandId': _newOrganizationCommandId(),
          ..._agentAccountPayload(agent),
          'assignmentStartsAt': assignmentStartsAt?.toUtc().toIso8601String(),
          'assignmentReason': assignmentReason.trim(),
          'assignAsHead': assignAsHead,
        },
      );
      return (result.data['uid'] ?? '').toString();
    } on FirebaseFunctionsException catch (error, stackTrace) {
      log('UserManagementRepository::createAgentAccount error => $error');
      log('UserManagementRepository::createAgentAccount stackTrace => $stackTrace');
      throw AgentProvisioningException(
        code: error.code,
        message: error.message ?? 'Unable to create the agent account.',
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::createAgentAccount error => $error');
      log('UserManagementRepository::createAgentAccount stackTrace => $stackTrace');
      throw const AgentProvisioningException(
        code: 'unknown',
        message: 'Unable to create the agent account.',
      );
    }
  }

  Future<AgentAccountMigrationResult> migrateLegacyAgentAccount(
    String legacyAgentId,
  ) async {
    try {
      final callable =
          firebaseFunctions.httpsCallable('migrateLegacyAgentAccount');
      final result = await callable.call<Map<String, dynamic>>({
        'legacyAgentId': legacyAgentId,
      });
      final data = result.data;
      return AgentAccountMigrationResult(
        uid: (data['uid'] ?? '').toString(),
        authAccountCreated: data['authAccountCreated'] == true,
        alreadyCanonical: data['alreadyCanonical'] == true,
        requiresOrganizationAssignment:
            data['requiresOrganizationAssignment'] != false,
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      log('UserManagementRepository::migrateLegacyAgentAccount error => $error');
      log(
        'UserManagementRepository::migrateLegacyAgentAccount stackTrace => $stackTrace',
      );
      throw AgentProvisioningException(
        code: error.code,
        message: error.message ?? 'Unable to migrate the agent account.',
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::migrateLegacyAgentAccount error => $error');
      log(
        'UserManagementRepository::migrateLegacyAgentAccount stackTrace => $stackTrace',
      );
      throw const AgentProvisioningException(
        code: 'unknown',
        message: 'Unable to migrate the agent account.',
      );
    }
  }

  Future<void> updateAgent(UserManagementAgent agent) async {
    try {
      final callable = firebaseFunctions.httpsCallable('updateAgentAccount');
      await callable.call<Map<String, dynamic>>({
        'commandId': _newOrganizationCommandId(),
        'uid': agent.id.trim(),
        ..._agentAccountPayload(agent),
      });
    } on FirebaseFunctionsException catch (error, stackTrace) {
      log('UserManagementRepository::updateAgent error => $error');
      log('UserManagementRepository::updateAgent stackTrace => $stackTrace');
      throw AgentProvisioningException(
        code: error.code,
        message: error.message ?? 'Unable to update the agent account.',
      );
    }
  }

  Map<String, dynamic> _agentAccountPayload(UserManagementAgent agent) {
    return {
      'firstName': agent.firstName.trim(),
      'name': agent.name.trim(),
      'postName': agent.postName.trim(),
      'matricule': agent.matricule.trim(),
      'sex': agent.sex?.value,
      'email': agent.email.trim().toLowerCase(),
      'profilePictureUrl': agent.profilePictureUrl,
      'jobTitle': agent.jobTitle.trim(),
      'organizationId': agent.organizationId.trim(),
      'organizationUnitId': agent.primaryOrganizationUnitId.trim(),
      'isActive': agent.isActive,
      'modulePermissions': agent.modulePermissions,
    };
  }

  String _newOrganizationCommandId() => firestoreClient.firestore
      .collection('organizationCommandReceipts')
      .doc()
      .id;

  Future<List<UserManagementModule>> fetchModules() async {
    try {
      final documents =
          await firestoreClient.fetchAll(collection: _modulesPath);
      final modules = documents
          .map((document) =>
              UserManagementModule.fromMap(document.data, id: document.id))
          .toList();

      modules.sort(
        (left, right) => left.nameLower.compareTo(right.nameLower),
      );

      return modules;
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchModules error => $error');
      log('UserManagementRepository::fetchModules stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Stream<List<UserManagementModule>> watchModules() {
    try {
      return firestoreClient.streamAll(collection: _modulesPath).map(
        (documents) {
          final modules = documents
              .map((document) =>
                  UserManagementModule.fromMap(document.data, id: document.id))
              .toList();

          modules.sort(
            (left, right) => left.nameLower.compareTo(right.nameLower),
          );

          return modules;
        },
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::watchModules error => $error');
      log('UserManagementRepository::watchModules stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> addModule(UserManagementModule module) async {
    try {
      await firestoreClient.add(
        collection: _modulesPath,
        data: module.toMap(),
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::addModule error => $error');
      log('UserManagementRepository::addModule stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<UserManagementModule> fetchModuleById(String id) async {
    try {
      final document =
          await firestoreClient.fetchById(collection: _modulesPath, id: id);
      return UserManagementModule.fromMap(document.data, id: document.id);
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchModuleById error => $error');
      log('UserManagementRepository::fetchModuleById stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> updateModule(UserManagementModule module) async {
    try {
      await firestoreClient.firestore
          .collection(_modulesPath)
          .doc(module.id)
          .update({
        ...module.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      log('UserManagementRepository::updateModule error => $error');
      log('UserManagementRepository::updateModule stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> deleteModule(String moduleId) async {
    try {
      await firestoreClient.delete(
        collection: _modulesPath,
        id: moduleId,
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::deleteModule error => $error');
      log('UserManagementRepository::deleteModule stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Query<Map<String, dynamic>> _organizationQuery(
    OrganizationListQuery request, {
    bool includeSearchStart = true,
  }) {
    _validateLimit(request.limit);
    Query<Map<String, dynamic>> query =
        firestoreClient.firestore.collection(_organizationsPath);
    query = _applyStatusFilter(
      query,
      request.status.firestoreValues,
    );
    query = query.orderBy('nameLower').orderBy(FieldPath.documentId);
    return _applyPrefixSearch(
      query,
      request.normalizedSearch,
      includeStart: includeSearchStart,
    );
  }

  Query<Map<String, dynamic>> _organizationUnitQuery(
    OrganizationUnitListQuery request, {
    bool includeSearchStart = true,
  }) {
    _validateLimit(request.limit);
    Query<Map<String, dynamic>> query = firestoreClient.firestore
        .collection(_organizationUnitsPath)
        .where('organizationId', isEqualTo: request.organizationId.trim());
    final type = request.normalizedType;
    if (type != null) query = query.where('type', isEqualTo: type);
    query = _applyStatusFilter(query, request.status.firestoreValues);
    query = query.orderBy('nameLower').orderBy(FieldPath.documentId);
    return _applyPrefixSearch(
      query,
      request.normalizedSearch,
      includeStart: includeSearchStart,
    );
  }

  Query<Map<String, dynamic>> _agentDirectoryQuery(
    AgentDirectoryListQuery request, {
    bool includeSearchStart = true,
  }) {
    _validateLimit(request.limit);
    Query<Map<String, dynamic>> query = firestoreClient.firestore
        .collection(_agentDirectoryPath)
        .where('organizationId', isEqualTo: request.organizationId.trim());
    if (request.scopeUnitId.trim().isNotEmpty) {
      query = query.where(
        'scopeKeys',
        arrayContains: 'unit:${request.scopeUnitId.trim()}',
      );
    }
    query = switch (request.status) {
      AgentDirectoryStatusFilter.active =>
        query.where('isActive', isEqualTo: true),
      AgentDirectoryStatusFilter.inactive =>
        query.where('isActive', isEqualTo: false),
      AgentDirectoryStatusFilter.all => query,
    };
    query = query.orderBy('displayNameLower').orderBy(FieldPath.documentId);
    return _applyPrefixSearch(
      query,
      request.normalizedSearch,
      includeStart: includeSearchStart,
    );
  }

  Query<Map<String, dynamic>> _organizationAssignmentQuery(
    OrganizationAssignmentQuery request,
  ) {
    _validateLimit(request.limit);
    Query<Map<String, dynamic>> query = firestoreClient.firestore
        .collection(_organizationAssignmentsPath)
        .where('organizationId', isEqualTo: request.organizationId.trim());
    query = request.isAgentQuery
        ? query.where('agentId', isEqualTo: request.agentId.trim())
        : query.where('unitId', isEqualTo: request.unitId.trim());
    return query
        .orderBy('startsAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  Query<Map<String, dynamic>> _organizationAuditQuery(
    OrganizationAuditQuery request,
  ) {
    _validateLimit(request.limit);
    return firestoreClient.firestore
        .collection(_organizationAuditEventsPath)
        .where('organizationId', isEqualTo: request.organizationId.trim())
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  Query<Map<String, dynamic>> _applyStatusFilter(
    Query<Map<String, dynamic>> query,
    List<String>? statuses,
  ) {
    if (statuses == null || statuses.isEmpty) return query;
    return statuses.length == 1
        ? query.where('status', isEqualTo: statuses.single)
        : query.where('status', whereIn: statuses);
  }

  Query<Map<String, dynamic>> _applyPrefixSearch(
    Query<Map<String, dynamic>> query,
    String search, {
    required bool includeStart,
  }) {
    if (search.isEmpty) return query;
    final bounded = query.endAt(['$search\uf8ff']);
    return includeStart ? bounded.startAt([search]) : bounded;
  }

  bool _hasPageCursor(OrganizationPageRequest request) =>
      request.afterNameLower?.trim().isNotEmpty == true ||
      request.afterId?.trim().isNotEmpty == true;

  Query<Map<String, dynamic>> _withPageCursor(
    Query<Map<String, dynamic>> query,
    OrganizationPageRequest request,
  ) {
    final nameLower = request.afterNameLower?.trim() ?? '';
    final id = request.afterId?.trim() ?? '';
    if (nameLower.isEmpty && id.isEmpty) return query;
    if (nameLower.isEmpty || id.isEmpty) {
      throw ArgumentError(
        'Both cursor sort value and document ID are required.',
      );
    }
    return query.startAfter([nameLower, id]);
  }

  OrganizationPage<T> _pageFromDocuments<T>(
    List<T> items,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    int limit,
    String sortField,
  ) {
    if (documents.isEmpty || documents.length < limit) {
      return OrganizationPage<T>(items: items, nextCursor: null);
    }
    final last = documents.last;
    return OrganizationPage<T>(
      items: items,
      nextCursor: OrganizationPageCursor(
        nameLower: (last.data()[sortField] ?? '').toString(),
        id: last.id,
      ),
    );
  }

  Query<Map<String, dynamic>> _withTimelineCursor(
    Query<Map<String, dynamic>> query,
    OrganizationTimelinePageRequest request,
  ) {
    if (!request.hasCursor) {
      if (request.afterTimestamp == null &&
          (request.afterId?.trim().isEmpty ?? true)) {
        return query;
      }
      throw ArgumentError(
        'Both cursor timestamp and document ID are required.',
      );
    }
    return query.startAfter([
      Timestamp.fromDate(request.afterTimestamp!),
      request.afterId!.trim(),
    ]);
  }

  OrganizationTimelinePage<T> _timelinePageFromDocuments<T>(
    List<T> items,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    int limit,
    String timestampField,
  ) {
    if (documents.isEmpty || documents.length < limit) {
      return OrganizationTimelinePage<T>(items: items, nextCursor: null);
    }
    final last = documents.last;
    final rawTimestamp = last.data()[timestampField];
    final timestamp = rawTimestamp is Timestamp
        ? rawTimestamp.toDate()
        : DateTime.tryParse(rawTimestamp?.toString() ?? '');
    if (timestamp == null) {
      throw StateError('The timeline cursor timestamp is missing.');
    }
    return OrganizationTimelinePage<T>(
      items: items,
      nextCursor: OrganizationTimelineCursor(
        timestamp: timestamp,
        id: last.id,
      ),
    );
  }

  static void _validateLimit(int limit) {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }
  }
}

final userManagementRepositoryProvider =
    Provider<UserManagementRepository>((ref) {
  return UserManagementRepository(
    ref.read(firestoreClientProvider),
    ref.read(firebaseFunctionsProvider),
  );
});

class AgentProvisioningException implements Exception {
  const AgentProvisioningException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => message;
}

class OrganizationCommandException implements Exception {
  const OrganizationCommandException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => message;
}

class AgentAccountMigrationResult {
  const AgentAccountMigrationResult({
    required this.uid,
    required this.authAccountCreated,
    required this.alreadyCanonical,
    required this.requiresOrganizationAssignment,
  });

  final String uid;
  final bool authAccountCreated;
  final bool alreadyCanonical;
  final bool requiresOrganizationAssignment;
}
