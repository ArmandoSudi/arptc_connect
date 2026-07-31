import 'dart:convert';
import 'dart:io';

import 'package:arptc_connect/modules/itsm/support/domain/initial_catalogue_definitions.dart';

void main() {
  final generatedAt = DateTime.utc(2026, 7, 31);
  const actor = 'itsm-phase2-seed';
  final items = InitialCatalogueDefinitions.build(
    createdAt: generatedAt,
    createdBy: actor,
  );
  final workflowIds = items.map((item) => item.workflow.id).toSet().toList()
    ..sort();
  final slaIds = items.map((item) => item.slaPolicy.id).toSet().toList()
    ..sort();

  final documents = <Map<String, Object?>>[];
  for (final workflowId in workflowIds) {
    final matching = items.where((item) => item.workflow.id == workflowId);
    final approvalPolicyIds = matching
        .map((item) => item.approvalPolicyId)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final fulfilmentGroup = matching.first.fulfilmentGroupId;
    documents.addAll([
      _document('workflowDefinitions/$workflowId', {
        'name': _title(workflowId),
        'status': 'published',
        'publishedVersion': 1,
        'seedSource': actor,
        'seedVersion': 1,
        'createdAt': generatedAt,
        'updatedAt': generatedAt,
      }),
      _document('workflowDefinitions/$workflowId/versions/000001', {
        'version': 1,
        'status': 'published',
        'startState': 'submitted',
        'states': const [
          'submitted',
          'awaiting_approval',
          'approved',
          'assigned',
          'in_fulfilment',
          'awaiting_user',
          'fulfilled',
          'closed',
          'rejected',
          'cancelled',
        ],
        'approvalSteps': approvalPolicyIds
            .map(
              (policyId) => {
                'id': policyId,
                'name': _title(policyId),
                'approverGroupId': _approvalGroup(policyId),
                'sequence': 1,
                'required': true,
              },
            )
            .toList(growable: false),
        'fulfilmentTasks': [
          {
            'id': 'fulfil-request',
            'title': const {
              'en': 'Fulfil request',
              'fr': 'Executer la demande',
            },
            'assignedGroupId': fulfilmentGroup,
            'isInternal': false,
            'required': true,
          },
        ],
        'seedSource': actor,
        'seedVersion': 1,
        'publishedAt': generatedAt,
      }),
    ]);
  }
  for (final slaId in slaIds) {
    documents.addAll([
      _document('slaPolicies/$slaId', {
        'name': _title(slaId),
        'status': 'published',
        'publishedVersion': 1,
        'seedSource': actor,
        'seedVersion': 1,
        'createdAt': generatedAt,
        'updatedAt': generatedAt,
      }),
      _document('slaPolicies/$slaId/versions/000001', {
        'version': 1,
        'status': 'published',
        'responseTargetMinutes': _responseMinutes(slaId),
        'fulfilmentTargetMinutes': _fulfilmentMinutes(slaId),
        'warningThresholdPercent': 75,
        'pauseStatuses': const ['awaiting_user'],
        'businessHoursPolicyId': 'arptc-standard-hours',
        'seedSource': actor,
        'seedVersion': 1,
        'publishedAt': generatedAt,
      }),
    ]);
  }
  for (final item in items) {
    documents.add(_document(
      'serviceCatalogItems/${item.id}',
      item.toFirestore(),
    ));
  }

  const encoder = JsonEncoder.withIndent('  ');
  stdout.writeln(encoder.convert({
    'schemaVersion': 1,
    'generatedAt': _jsonValue(generatedAt),
    'documents': documents,
  }));
}

Map<String, Object?> _document(String path, Map<String, Object?> data) => {
      'path': path,
      'data': _jsonValue(data),
    };

Object? _jsonValue(Object? value) {
  if (value is DateTime) return {'@timestamp': value.toUtc().toIso8601String()};
  if (value is Map) {
    return value.map(
      (key, child) => MapEntry(key.toString(), _jsonValue(child)),
    );
  }
  if (value is Iterable) return value.map(_jsonValue).toList(growable: false);
  return value;
}

String _title(String value) => value
    .split('-')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _approvalGroup(String policyId) {
  if (policyId.contains('security')) return 'cybersecurity';
  if (policyId.contains('licence')) return 'licence-management';
  if (policyId.contains('asset')) return 'asset-management';
  if (policyId.contains('change')) return 'change-management';
  return 'line-managers';
}

int _responseMinutes(String slaId) {
  if (slaId.contains('incident')) return 30;
  if (slaId.contains('security')) return 60;
  return 240;
}

int _fulfilmentMinutes(String slaId) {
  if (slaId.contains('incident')) return 480;
  if (slaId.contains('security')) return 1440;
  if (slaId.contains('asset')) return 4320;
  if (slaId.contains('change')) return 2880;
  return 1440;
}
