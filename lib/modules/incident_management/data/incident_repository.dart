import 'package:arptc_connect/modules/incident_management/data/incident_actor.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_audit_log.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_category.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_comment.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_user.dart';
import 'package:arptc_connect/modules/incident_management/domain/it_service.dart';

abstract class IncidentRepository {
  Stream<List<IncidentTicket>> watchMyActiveTickets(String userEmail);

  Stream<List<IncidentTicket>> watchMyClosedAndArchivedTickets(
      String userEmail);

  Stream<List<IncidentTicket>> watchAllActiveTicketsForManagers();

  Stream<List<IncidentTicket>> watchAllClosedTicketsForManagers();

  Stream<List<IncidentTicket>> watchAssignedToMeTickets(String userId);

  Stream<List<IncidentTicket>> watchAllTicketsForAdmin();

  Stream<IncidentTicket?> watchTicketById(String ticketId);

  Stream<List<IncidentCategory>> watchCategories();

  Stream<List<IncidentCategory>> watchAllCategoriesForManagement();

  Stream<List<ItService>> watchItServices();

  Stream<List<ItService>> watchAllItServicesForManagement();

  Stream<List<IncidentUser>> watchItStaffUsers();

  Stream<List<IncidentUser>> watchAgents();

  Stream<List<IncidentComment>> watchComments(String ticketId);

  Stream<List<IncidentAuditLog>> watchAuditLogs(String ticketId);

  Future<String> createTicket(IncidentTicket ticket, IncidentActor actor);

  Future<void> saveCategory(IncidentCategory category, IncidentActor actor);

  Future<void> saveItService(ItService service, IncidentActor actor);

  Future<void> updateManagerFields({
    required String ticketId,
    required Map<String, dynamic> fields,
    required IncidentActor actor,
  });

  Future<void> addInternalNote({
    required String ticketId,
    required String body,
    required IncidentActor actor,
  });

  Future<void> markTicketResolved({
    required String ticketId,
    required String resolutionSummary,
    required String resolutionCode,
    required IncidentActor actor,
  });

  Future<void> closeTicket({
    required String ticketId,
    required String resolutionSummary,
    required String resolutionCode,
    required IncidentActor actor,
  });

  Future<void> cancelTicket({
    required String ticketId,
    required IncidentActor actor,
  });
}
