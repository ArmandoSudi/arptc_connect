import 'package:arptc_connect/modules/usermanagement/domain/organization_architecture_audit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_audit_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrganizationAuditEvent', () {
    test('parses immutable audit evidence and prioritizes the agent subject',
        () {
      final createdAt = DateTime.utc(2026, 8, 11, 9, 30);
      final event = OrganizationAuditEvent.fromMap(
        {
          'eventType': ' AGENT_TRANSFERRED ',
          'command': ' transferAgentOrganization ',
          'commandId': ' command-42 ',
          'actorUid': ' manager-1 ',
          'organizationId': ' org-a ',
          'unitId': ' unit-b ',
          'agentId': ' agent-a ',
          'assignmentId': ' assignment-b ',
          'reason': ' Operational transfer ',
          'before': {'unitId': 'unit-a'},
          'after': {'unitId': 'unit-b'},
          'createdAt': Timestamp.fromDate(createdAt),
        },
        id: 'event-42',
      );

      expect(event.id, 'event-42');
      expect(event.eventType, 'AGENT_TRANSFERRED');
      expect(event.command, 'transferAgentOrganization');
      expect(event.commandId, 'command-42');
      expect(event.actorUid, 'manager-1');
      expect(event.reason, 'Operational transfer');
      expect(event.createdAt.toUtc(), createdAt);
      expect(event.subjectId, 'agent-a');
      expect(event.before, {'unitId': 'unit-a'});
      expect(event.after, {'unitId': 'unit-b'});
      expect(() => event.before['forged'] = true, throwsUnsupportedError);
      expect(() => event.after.clear(), throwsUnsupportedError);
    });

    test('falls back from unit to assignment to organization subject', () {
      OrganizationAuditEvent event(Map<String, dynamic> values) =>
          OrganizationAuditEvent.fromMap(values, id: 'event');

      expect(
        event({'organizationId': 'org-a', 'unitId': 'unit-a'}).subjectId,
        'unit-a',
      );
      expect(
        event({
          'organizationId': 'org-a',
          'assignmentId': 'assignment-a',
        }).subjectId,
        'assignment-a',
      );
      expect(event({'organizationId': 'org-a'}).subjectId, 'org-a');
    });

    test('accepts ISO dates and safely defaults malformed fields', () {
      final parsed = OrganizationAuditEvent.fromMap(
        {
          'createdAt': '2026-08-11T09:30:00.000Z',
          'before': 'not-a-map',
          'after': null,
        },
        id: 'event-iso',
      );
      final malformed = OrganizationAuditEvent.fromMap(
        {'createdAt': 'not-a-date'},
        id: 'event-malformed',
      );

      expect(parsed.createdAt, DateTime.utc(2026, 8, 11, 9, 30));
      expect(parsed.before, isEmpty);
      expect(parsed.after, isEmpty);
      expect(
        malformed.createdAt,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
  });

  group('OrganizationArchitectureAuditReport', () {
    test('parses counts, issues, repaired IDs, and alternate assignment keys',
        () {
      final report = OrganizationArchitectureAuditReport.fromMap({
        'organizationId': ' org-a ',
        'dryRun': true,
        'truncated': false,
        'scanned': {
          'agents': '12',
          'units': 4,
          'invalid': 'not-a-number',
        },
        'issues': [
          {
            'type': 'STALE_AGENT_PROJECTION',
            'agentId': ' agent-a ',
            'assignmentIds': ['assignment-a', ' ', null],
          },
          {
            'type': 'DUPLICATE_HEAD',
            'unitId': ' unit-a ',
            'assignments': ['head-a', 'head-b'],
          },
          'ignored',
        ],
        'repairedCount': '2',
        'repairedAgentIds': ['agent-a', 'agent-b'],
        'skippedAgentIds': 'agent-c',
      });

      expect(report.organizationId, 'org-a');
      expect(report.scanned, {'agents': 12, 'units': 4, 'invalid': 0});
      expect(report.issueCount, 2);
      expect(report.canRepair, isTrue);
      expect(report.isClean, isFalse);
      expect(report.repairedCount, 2);
      expect(report.repairedAgentIds, ['agent-a', 'agent-b']);
      expect(report.skippedAgentIds, ['agent-c']);
      expect(report.issues.first.subjectId, 'agent-a');
      expect(report.issues.last.subjectId, 'unit-a');
      expect(report.issues.last.assignmentIds, ['head-a', 'head-b']);
      expect(() => report.scanned['agents'] = 0, throwsUnsupportedError);
      expect(() => report.issues.clear(), throwsUnsupportedError);
      expect(
          () => report.repairedAgentIds.add('forged'), throwsUnsupportedError);
    });

    test(
        'repair eligibility fails closed for clean, truncated, and applied reports',
        () {
      OrganizationArchitectureAuditReport report({
        required bool dryRun,
        required bool truncated,
        required List<Map<String, dynamic>> issues,
      }) {
        return OrganizationArchitectureAuditReport.fromMap({
          'organizationId': 'org-a',
          'dryRun': dryRun,
          'truncated': truncated,
          'issues': issues,
        });
      }

      final clean = report(dryRun: true, truncated: false, issues: const []);
      final truncated = report(
        dryRun: true,
        truncated: true,
        issues: const [
          {'type': 'STALE'},
        ],
      );
      final applied = report(
        dryRun: false,
        truncated: false,
        issues: const [
          {'type': 'STALE'},
        ],
      );

      expect(clean.isClean, isTrue);
      expect(clean.canRepair, isFalse);
      expect(truncated.isClean, isFalse);
      expect(truncated.canRepair, isFalse);
      expect(applied.canRepair, isFalse);
    });

    test('issue subject falls back to assignments when no entity ID exists',
        () {
      final issue = OrganizationArchitectureIssue.fromMap({
        'type': 'DUPLICATE_ASSIGNMENT',
        'assignmentId': 'assignment-a',
      });

      expect(issue.type, 'DUPLICATE_ASSIGNMENT');
      expect(issue.assignmentIds, ['assignment-a']);
      expect(issue.subjectId, 'assignment-a');
    });
  });
}
