import 'package:arptc_connect/modules/incident_management/application/incident_notification_factory.dart';
import 'package:arptc_connect/modules/incident_management/data/incident_actor.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentNotificationFactory', () {
    test('targets every incident manager when a user submits a ticket', () {
      final notification = IncidentNotificationFactory.submittedForManagers(
        ticket: _ticket(),
        actor: _userActor,
      );

      expect(notification.eventType, 'incident.created');
      expect(notification.route, '/service/incidents/manager/ticket-1');
      expect(notification.target.type, NotificationTargetType.moduleRole);
      expect(notification.target.moduleKey, 'ticketing');
      expect(notification.target.roles, ['MANAGER']);
    });

    test('notifies only the manager receiving an assignment', () {
      final notification = IncidentNotificationFactory.assignedToManager(
        ticket: _ticket(),
        actor: _otherManager,
        assignedToUserId: 'assigned-manager',
        assignedToEmail: 'assigned@arptc.cd',
      );

      expect(notification, isNotNull);
      expect(notification!.eventType, 'incident.assigned');
      expect(notification.target.type, NotificationTargetType.users);
      expect(notification.target.userIds, ['assigned-manager']);
      expect(notification.target.userEmails, ['assigned@arptc.cd']);
      expect(notification.route, '/service/incidents/manager/ticket-1');
    });

    test('continues notifying the assignee through ticket closure', () {
      final notification = IncidentNotificationFactory.closedForAssignee(
        ticket: _ticket(
          assignedToUserId: 'assigned-manager',
          assignedToEmail: 'assigned@arptc.cd',
        ),
        actor: _otherManager,
      );

      expect(notification, isNotNull);
      expect(notification!.eventType, 'incident.closed');
      expect(notification.target.userIds, ['assigned-manager']);
      expect(notification.target.userEmails, ['assigned@arptc.cd']);
    });

    test('does not notify a manager about their own action', () {
      final ticket = _ticket(
        assignedToUserId: 'assigned-manager',
        assignedToEmail: 'assigned@arptc.cd',
      );

      expect(
        IncidentNotificationFactory.resolvedForAssignee(
          ticket: ticket,
          actor: _assignedManager,
        ),
        isNull,
      );
    });

    test('does not create personal events before assignment', () {
      expect(
        IncidentNotificationFactory.updatedForAssignee(
          ticket: _ticket(),
          actor: _otherManager,
          assignedToUserId: '',
          assignedToEmail: '',
        ),
        isNull,
      );
    });
  });
}

const _userActor = IncidentActor(
  userId: 'requester',
  name: 'Requesting User',
  email: 'requester@arptc.cd',
  role: IncidentRole.user,
);

const _otherManager = IncidentActor(
  userId: 'triage-manager',
  name: 'Triage Manager',
  email: 'triage@arptc.cd',
  role: IncidentRole.manager,
);

const _assignedManager = IncidentActor(
  userId: 'assigned-manager',
  name: 'Assigned Manager',
  email: 'assigned@arptc.cd',
  role: IncidentRole.manager,
);

IncidentTicket _ticket({
  String assignedToUserId = '',
  String assignedToEmail = '',
}) {
  return IncidentTicket.empty().copyWith(
    id: 'ticket-1',
    ticketNumber: 'INC-001',
    title: 'Internet unavailable',
    assignedToUserId: assignedToUserId,
    assignedToEmail: assignedToEmail,
  );
}
