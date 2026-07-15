import 'package:arptc_connect/modules/incident_management/data/incident_actor.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_event.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_target.dart';

class IncidentNotificationFactory {
  const IncidentNotificationFactory._();

  static NotificationEvent submittedForManagers({
    required IncidentTicket ticket,
    required IncidentActor actor,
  }) {
    return _event(
      eventType: 'incident.created',
      title: 'New IT incident',
      body: '${_actorName(actor)} submitted ${_ticketLabel(ticket)}.',
      ticket: ticket,
      actor: actor,
      target: NotificationTarget.moduleRole(
        moduleKey: 'ticketing',
        roles: const ['MANAGER'],
      ),
    );
  }

  static NotificationEvent? assignedToManager({
    required IncidentTicket ticket,
    required IncidentActor actor,
    required String assignedToUserId,
    required String assignedToEmail,
  }) {
    return _forAssignee(
      eventType: 'incident.assigned',
      title: 'Incident assigned to you',
      body: '${_ticketLabel(ticket)} was assigned to you by '
          '${_actorName(actor)}.',
      ticket: ticket,
      actor: actor,
      assignedToUserId: assignedToUserId,
      assignedToEmail: assignedToEmail,
    );
  }

  static NotificationEvent? updatedForAssignee({
    required IncidentTicket ticket,
    required IncidentActor actor,
    required String assignedToUserId,
    required String assignedToEmail,
  }) {
    return _forAssignee(
      eventType: 'incident.updated',
      title: 'Assigned incident updated',
      body: '${_ticketLabel(ticket)} was updated by ${_actorName(actor)}.',
      ticket: ticket,
      actor: actor,
      assignedToUserId: assignedToUserId,
      assignedToEmail: assignedToEmail,
    );
  }

  static NotificationEvent? internalNoteForAssignee({
    required IncidentTicket ticket,
    required IncidentActor actor,
  }) {
    return _forCurrentAssignee(
      eventType: 'incident.internal_note_added',
      title: 'New activity on assigned incident',
      body: '${_actorName(actor)} added an internal note to '
          '${_ticketLabel(ticket)}.',
      ticket: ticket,
      actor: actor,
    );
  }

  static NotificationEvent? resolvedForAssignee({
    required IncidentTicket ticket,
    required IncidentActor actor,
  }) {
    return _forCurrentAssignee(
      eventType: 'incident.resolved',
      title: 'Assigned incident resolved',
      body: '${_ticketLabel(ticket)} was marked resolved by '
          '${_actorName(actor)}.',
      ticket: ticket,
      actor: actor,
    );
  }

  static NotificationEvent? closedForAssignee({
    required IncidentTicket ticket,
    required IncidentActor actor,
  }) {
    return _forCurrentAssignee(
      eventType: 'incident.closed',
      title: 'Assigned incident closed',
      body: '${_ticketLabel(ticket)} was closed by ${_actorName(actor)}.',
      ticket: ticket,
      actor: actor,
    );
  }

  static NotificationEvent? cancelledForAssignee({
    required IncidentTicket ticket,
    required IncidentActor actor,
  }) {
    return _forCurrentAssignee(
      eventType: 'incident.cancelled',
      title: 'Assigned incident cancelled',
      body: '${_ticketLabel(ticket)} was cancelled by ${_actorName(actor)}.',
      ticket: ticket,
      actor: actor,
    );
  }

  static NotificationEvent? _forCurrentAssignee({
    required String eventType,
    required String title,
    required String body,
    required IncidentTicket ticket,
    required IncidentActor actor,
  }) {
    return _forAssignee(
      eventType: eventType,
      title: title,
      body: body,
      ticket: ticket,
      actor: actor,
      assignedToUserId: ticket.assignedToUserId,
      assignedToEmail: ticket.assignedToEmail,
    );
  }

  static NotificationEvent? _forAssignee({
    required String eventType,
    required String title,
    required String body,
    required IncidentTicket ticket,
    required IncidentActor actor,
    required String assignedToUserId,
    required String assignedToEmail,
  }) {
    final userId = assignedToUserId.trim();
    final email = assignedToEmail.trim().toLowerCase();
    if ((userId.isEmpty && email.isEmpty) ||
        _actorMatchesAssignee(actor, userId, email)) {
      return null;
    }

    return _event(
      eventType: eventType,
      title: title,
      body: body,
      ticket: ticket,
      actor: actor,
      target: NotificationTarget.users(
        userIds: userId.isEmpty ? const [] : [userId],
        userEmails: email.isEmpty ? const [] : [email],
      ),
    );
  }

  static NotificationEvent _event({
    required String eventType,
    required String title,
    required String body,
    required IncidentTicket ticket,
    required IncidentActor actor,
    required NotificationTarget target,
  }) {
    return NotificationEvent(
      id: '',
      eventType: eventType,
      moduleKey: 'ticketing',
      title: title,
      body: body,
      entityType: 'incidentTicket',
      entityId: ticket.id,
      route: '/service/incidents/manager/${ticket.id}',
      createdByUserId: actor.userId,
      createdByName: actor.name,
      createdByEmail: actor.email,
      target: target,
    );
  }

  static bool _actorMatchesAssignee(
    IncidentActor actor,
    String assignedToUserId,
    String assignedToEmail,
  ) {
    if (assignedToUserId.isNotEmpty &&
        actor.userId.trim() == assignedToUserId) {
      return true;
    }
    final actorEmail = actor.email.trim().toLowerCase();
    return actorEmail.isNotEmpty &&
        assignedToEmail.isNotEmpty &&
        actorEmail == assignedToEmail;
  }

  static String _ticketLabel(IncidentTicket ticket) {
    final number = ticket.ticketNumber.trim();
    final title = ticket.title.trim();
    if (number.isEmpty) {
      return title.isEmpty ? 'the incident' : title;
    }
    return title.isEmpty ? number : '$number: $title';
  }

  static String _actorName(IncidentActor actor) {
    final name = actor.name.trim();
    return name.isEmpty ? 'IT support' : name;
  }
}
