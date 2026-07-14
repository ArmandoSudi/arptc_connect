import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/incident_management/data/incident_actor.dart';
import 'package:arptc_connect/modules/incident_management/data/incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_audit_log.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_category.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_comment.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_resolution_code.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_user.dart';
import 'package:arptc_connect/modules/incident_management/domain/it_service.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_event.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_target.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return FirestoreIncidentRepository(ref.read(fireStoreProvider));
});

class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _tickets =>
      firestore.collection('incidentTickets');

  CollectionReference<Map<String, dynamic>> get _categories =>
      firestore.collection('incidentCategories');

  CollectionReference<Map<String, dynamic>> get _itServices =>
      firestore.collection('itServices');

  CollectionReference<Map<String, dynamic>> get _resolutionCodes =>
      firestore.collection('incidentResolutionCodes');

  CollectionReference<Map<String, dynamic>> get _agents =>
      firestore.collection('agents');

  CollectionReference<Map<String, dynamic>> get _notificationEvents =>
      firestore.collection('notificationEvents');

  @override
  Stream<List<IncidentTicket>> watchMyActiveTickets(String userEmail) {
    return _watchTickets(
      _tickets
          .where('affectedUserEmail', isEqualTo: userEmail)
          .where('lifecycleState',
              isEqualTo: IncidentLifecycleState.active.value)
          .where('isDeleted', isEqualTo: false),
    );
  }

  @override
  Stream<List<IncidentTicket>> watchMyClosedAndArchivedTickets(
      String userEmail) {
    return _watchTickets(
      _tickets.where('affectedUserEmail', isEqualTo: userEmail).where(
        'lifecycleState',
        whereIn: [
          IncidentLifecycleState.closed.value,
          IncidentLifecycleState.archived.value,
        ],
      ).where('isDeleted', isEqualTo: false),
    );
  }

  @override
  Stream<List<IncidentTicket>> watchAllActiveTicketsForManagers() {
    return _watchTickets(
      _tickets
          .where('lifecycleState',
              isEqualTo: IncidentLifecycleState.active.value)
          .where('isDeleted', isEqualTo: false),
    );
  }

  @override
  Stream<List<IncidentTicket>> watchAllClosedTicketsForManagers() {
    return _watchTickets(
      _tickets
          .where('lifecycleState',
              isEqualTo: IncidentLifecycleState.closed.value)
          .where('isDeleted', isEqualTo: false),
    );
  }

  @override
  Stream<List<IncidentTicket>> watchAssignedToMeTickets(String userId) {
    return _watchTickets(
      _tickets
          .where('assignedToUserId', isEqualTo: userId)
          .where('lifecycleState',
              isEqualTo: IncidentLifecycleState.active.value)
          .where('isDeleted', isEqualTo: false),
    );
  }

  @override
  Stream<List<IncidentTicket>> watchAllTicketsForAdmin() {
    return _watchTickets(_tickets.where('isDeleted', isEqualTo: false));
  }

  @override
  Stream<IncidentTicket?> watchTicketById(String ticketId) {
    return _tickets.doc(ticketId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return IncidentTicket.fromFirestore(snapshot);
    });
  }

  @override
  Stream<List<IncidentCategory>> watchCategories() {
    return _categories.where('isActive', isEqualTo: true).snapshots().map(
      (snapshot) {
        final categories = snapshot.docs
            .map(IncidentCategory.fromFirestore)
            .toList()
          ..sort((left, right) => left.nameLower.compareTo(right.nameLower));
        return categories;
      },
    );
  }

  @override
  Stream<List<IncidentCategory>> watchAllCategoriesForManagement() {
    return _categories.snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map(IncidentCategory.fromFirestore)
          .toList()
        ..sort((left, right) => left.nameLower.compareTo(right.nameLower));
      return categories;
    });
  }

  @override
  Stream<List<ItService>> watchItServices() {
    return _itServices.where('isActive', isEqualTo: true).snapshots().map(
      (snapshot) {
        final services = snapshot.docs.map(ItService.fromFirestore).toList()
          ..sort((left, right) => left.nameLower.compareTo(right.nameLower));
        return services;
      },
    );
  }

  @override
  Stream<List<ItService>> watchAllItServicesForManagement() {
    return _itServices.snapshots().map((snapshot) {
      final services = snapshot.docs.map(ItService.fromFirestore).toList()
        ..sort((left, right) => left.nameLower.compareTo(right.nameLower));
      return services;
    });
  }

  @override
  Stream<List<IncidentResolutionCode>> watchResolutionCodes() {
    return watchAllResolutionCodesForManagement().map(
      (codes) => codes.where((code) => code.isActive).toList(),
    );
  }

  @override
  Stream<List<IncidentResolutionCode>> watchAllResolutionCodesForManagement() {
    return _resolutionCodes.snapshots().map((snapshot) {
      final codesByValue = {
        for (final code in IncidentResolutionCode.builtInDefaults)
          code.code: code,
      };
      for (final document in snapshot.docs) {
        final code = IncidentResolutionCode.fromFirestore(document);
        if (code.code.isNotEmpty) {
          codesByValue[code.code] = code;
        }
      }
      final codes = codesByValue.values.toList()
        ..sort((left, right) => left.code.compareTo(right.code));
      return codes;
    });
  }

  @override
  Stream<List<IncidentUser>> watchItStaffUsers() {
    return _agents
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map(IncidentUser.fromFirestore)
          .where((user) => user.role == IncidentRole.manager)
          .toList()
        ..sort(
          (left, right) => left.displayName
              .toLowerCase()
              .compareTo(right.displayName.toLowerCase()),
        );
      return users;
    });
  }

  @override
  Stream<List<IncidentUser>> watchAgents() {
    return _agents
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final agents = snapshot.docs.map(IncidentUser.fromFirestore).toList()
        ..sort(
          (left, right) => left.displayName
              .toLowerCase()
              .compareTo(right.displayName.toLowerCase()),
        );
      return agents;
    });
  }

  @override
  Stream<List<IncidentComment>> watchComments(String ticketId) {
    return _tickets
        .doc(ticketId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs
          .map((doc) => IncidentComment.fromFirestore(doc, ticketId: ticketId))
          .toList()
        ..sort(_compareByCreatedAt);
      return comments;
    });
  }

  @override
  Stream<List<IncidentAuditLog>> watchAuditLogs(String ticketId) {
    return _tickets
        .doc(ticketId)
        .collection('auditLogs')
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs
          .map((doc) => IncidentAuditLog.fromFirestore(doc, ticketId: ticketId))
          .toList()
        ..sort(_compareLogsByCreatedAt);
      return logs;
    });
  }

  @override
  Future<String> createTicket(
      IncidentTicket ticket, IncidentActor actor) async {
    final doc = _tickets.doc();
    final ticketNumber = _generateTicketNumber();
    final isManagerCategorized = actor.role == IncidentRole.manager &&
        ticket.categoryId.trim().isNotEmpty &&
        ticket.impact.trim().isNotEmpty &&
        ticket.urgency.trim().isNotEmpty;
    final impact = isManagerCategorized ? ticket.impact : '';
    final urgency = isManagerCategorized ? ticket.urgency : '';
    final priority = isManagerCategorized
        ? calculateIncidentPriority(impact: impact, urgency: urgency).value
        : IncidentPriority.none.value;
    final data = ticket
        .copyWith(
          id: doc.id,
          ticketNumber: ticketNumber,
          status: isManagerCategorized
              ? IncidentStatus.inProgress.value
              : IncidentStatus.open.value,
          lifecycleState: IncidentLifecycleState.active.value,
          categoryId: isManagerCategorized ? ticket.categoryId : '',
          categoryName: isManagerCategorized ? ticket.categoryName : '',
          subcategoryId: isManagerCategorized ? ticket.subcategoryId : '',
          subcategoryName: isManagerCategorized ? ticket.subcategoryName : '',
          impact: impact,
          urgency: urgency,
          priority: priority,
          attachmentCount: 0,
          commentCount: 0,
          isDeleted: false,
        )
        .toFirestore();

    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['lastStatusChangedAt'] = FieldValue.serverTimestamp();

    final batch = firestore.batch();
    batch.set(doc, data);
    batch.set(
      _notificationEvents.doc(),
      NotificationEvent(
        id: '',
        eventType: 'incident.created',
        moduleKey: 'ticketing',
        title: 'New IT incident',
        body: '${actor.name} submitted $ticketNumber: ${ticket.title}.',
        entityType: 'incidentTicket',
        entityId: doc.id,
        route: '/service/incidents/manager/${doc.id}',
        createdByUserId: actor.userId,
        createdByName: actor.name,
        createdByEmail: actor.email,
        target: NotificationTarget.moduleRole(
          moduleKey: 'ticketing',
          roles: const ['MANAGER'],
        ),
      ).toFirestore(),
    );
    _addAuditLogToBatch(
      batch: batch,
      ticketRef: doc,
      actor: actor,
      action: 'created',
      message: 'Incident ticket $ticketNumber created',
    );
    await batch.commit();
    return doc.id;
  }

  @override
  Future<void> saveCategory(
      IncidentCategory category, IncidentActor actor) async {
    final isNew = category.id.trim().isEmpty;
    final doc = isNew ? _categories.doc() : _categories.doc(category.id);
    final data = category.toFirestore()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    if (isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await doc.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> saveItService(ItService service, IncidentActor actor) async {
    final isNew = service.id.trim().isEmpty;
    final doc = isNew ? _itServices.doc() : _itServices.doc(service.id);
    final data = service.toFirestore()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    if (isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await doc.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> saveResolutionCode(
    IncidentResolutionCode resolutionCode,
    IncidentActor actor,
  ) async {
    final code = IncidentResolutionCode.normalizeCode(resolutionCode.code);
    final documentId = resolutionCode.id.trim().isEmpty
        ? code.toLowerCase()
        : resolutionCode.id.trim();
    final doc = _resolutionCodes.doc(documentId);
    final data = resolutionCode.toFirestore()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    if (resolutionCode.createdAt == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await doc.set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateManagerFields({
    required String ticketId,
    required Map<String, dynamic> fields,
    required IncidentActor actor,
  }) async {
    final ticketRef = _tickets.doc(ticketId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ticketRef);
      final current = IncidentTicket.fromFirestore(snapshot);
      final update = Map<String, dynamic>.from(fields)
        ..removeWhere((_, value) => value == null);

      final impact = (update['impact'] ?? current.impact).toString();
      final urgency = (update['urgency'] ?? current.urgency).toString();
      update['priority'] =
          calculateIncidentPriority(impact: impact, urgency: urgency).value;
      update['updatedAt'] = FieldValue.serverTimestamp();

      final newStatus = update['status']?.toString();
      if (newStatus != null && newStatus != current.status) {
        update['lastStatusChangedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(ticketRef, update);
      _addAuditLogToTransaction(
        transaction: transaction,
        ticketRef: ticketRef,
        actor: actor,
        action: 'updated',
        message: 'Incident ticket updated',
        changes: update,
      );
    });
  }

  @override
  Future<void> addInternalNote({
    required String ticketId,
    required String body,
    required IncidentActor actor,
  }) async {
    final ticketRef = _tickets.doc(ticketId);
    final commentRef = ticketRef.collection('comments').doc();
    final batch = firestore.batch();

    batch.set(commentRef, {
      'body': body.trim(),
      'createdByUserId': actor.userId,
      'createdByEmail': actor.email,
      'createdByName': actor.name,
      'createdByRole': actor.role.value,
      'isInternal': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(ticketRef, {
      'commentCount': FieldValue.increment(1),
      'lastCommentAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addAuditLogToBatch(
      batch: batch,
      ticketRef: ticketRef,
      actor: actor,
      action: 'internal_note_added',
      message: 'Internal note added',
    );

    await batch.commit();
  }

  @override
  Future<void> markTicketResolved({
    required String ticketId,
    required String resolutionSummary,
    required String resolutionCode,
    required IncidentActor actor,
  }) async {
    final ticketRef = _tickets.doc(ticketId);
    final batch = firestore.batch();

    batch.update(ticketRef, {
      'status': IncidentStatus.resolved.value,
      'lifecycleState': IncidentLifecycleState.active.value,
      'resolutionSummary': resolutionSummary.trim(),
      'resolutionCode': resolutionCode.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastStatusChangedAt': FieldValue.serverTimestamp(),
    });
    _addAuditLogToBatch(
      batch: batch,
      ticketRef: ticketRef,
      actor: actor,
      action: 'resolved',
      message: 'Incident ticket marked as resolved',
      changes: {
        'resolutionCode': resolutionCode.trim(),
      },
    );

    await batch.commit();
  }

  @override
  Future<void> closeTicket({
    required String ticketId,
    required String resolutionSummary,
    required String resolutionCode,
    required IncidentActor actor,
  }) async {
    final now = DateTime.now().toUtc();
    final ticketRef = _tickets.doc(ticketId);
    final batch = firestore.batch();

    batch.update(ticketRef, {
      'status': IncidentStatus.closed.value,
      'lifecycleState': IncidentLifecycleState.closed.value,
      'resolutionSummary': resolutionSummary.trim(),
      'resolutionCode': resolutionCode.trim(),
      'closedByUserId': actor.userId,
      'closedByName': actor.name,
      'closedAt': FieldValue.serverTimestamp(),
      'archiveEligibleAt': Timestamp.fromDate(now.add(const Duration(days: 7))),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastStatusChangedAt': FieldValue.serverTimestamp(),
    });
    _addAuditLogToBatch(
      batch: batch,
      ticketRef: ticketRef,
      actor: actor,
      action: 'closed',
      message: 'Incident ticket closed',
      changes: {
        'resolutionCode': resolutionCode.trim(),
      },
    );

    await batch.commit();
  }

  @override
  Future<void> cancelTicket({
    required String ticketId,
    required IncidentActor actor,
  }) async {
    final ticketRef = _tickets.doc(ticketId);
    final batch = firestore.batch();

    batch.update(ticketRef, {
      'status': IncidentStatus.cancelled.value,
      'lifecycleState': IncidentLifecycleState.closed.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastStatusChangedAt': FieldValue.serverTimestamp(),
    });
    _addAuditLogToBatch(
      batch: batch,
      ticketRef: ticketRef,
      actor: actor,
      action: 'cancelled',
      message: 'Incident ticket cancelled as a false alarm',
    );

    await batch.commit();
  }

  Stream<List<IncidentTicket>> _watchTickets(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots().map((snapshot) {
      final tickets = snapshot.docs.map(IncidentTicket.fromFirestore).toList()
        ..sort(_compareTickets);
      return tickets;
    });
  }

  int _compareTickets(IncidentTicket left, IncidentTicket right) {
    final leftDate = left.updatedAt ?? left.createdAt ?? DateTime(1900);
    final rightDate = right.updatedAt ?? right.createdAt ?? DateTime(1900);
    return rightDate.compareTo(leftDate);
  }

  int _compareByCreatedAt(IncidentComment left, IncidentComment right) {
    final leftDate = left.createdAt ?? DateTime(1900);
    final rightDate = right.createdAt ?? DateTime(1900);
    return leftDate.compareTo(rightDate);
  }

  int _compareLogsByCreatedAt(IncidentAuditLog left, IncidentAuditLog right) {
    final leftDate = left.createdAt ?? DateTime(1900);
    final rightDate = right.createdAt ?? DateTime(1900);
    return leftDate.compareTo(rightDate);
  }

  String _generateTicketNumber() {
    final now = DateTime.now().toUtc();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final millis = now.millisecondsSinceEpoch.toString();
    return 'INC-$year$month$day-${millis.substring(millis.length - 6)}';
  }

  void _addAuditLogToBatch({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> ticketRef,
    required IncidentActor actor,
    required String action,
    required String message,
    Map<String, dynamic> changes = const {},
  }) {
    batch.set(
        ticketRef.collection('auditLogs').doc(),
        _auditLogData(
          actor: actor,
          action: action,
          message: message,
          changes: changes,
        ));
  }

  void _addAuditLogToTransaction({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> ticketRef,
    required IncidentActor actor,
    required String action,
    required String message,
    Map<String, dynamic> changes = const {},
  }) {
    transaction.set(
        ticketRef.collection('auditLogs').doc(),
        _auditLogData(
          actor: actor,
          action: action,
          message: message,
          changes: changes,
        ));
  }

  Map<String, dynamic> _auditLogData({
    required IncidentActor actor,
    required String action,
    required String message,
    Map<String, dynamic> changes = const {},
  }) {
    return {
      'action': action,
      'message': message,
      'actorUserId': actor.userId,
      'actorEmail': actor.email,
      'actorName': actor.name,
      'actorRole': actor.role.value,
      'changes': _serializableChanges(changes),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _serializableChanges(Map<String, dynamic> changes) {
    final serialized = <String, dynamic>{};
    changes.forEach((key, value) {
      if (value is FieldValue) {
        return;
      }
      serialized[key] = value;
    });
    return serialized;
  }
}
