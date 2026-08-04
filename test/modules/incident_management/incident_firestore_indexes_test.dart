import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore manifest covers every Incident Management query', () {
    final manifest = jsonDecode(
      File('firestore.indexes.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final indexes =
        (manifest['indexes'] as List<dynamic>).cast<Map<String, dynamic>>();

    final signatures = indexes.map(_indexSignature).toSet();

    expect(
      signatures,
      containsAll(<String>{
        _signature('incidentTickets', <String>[
          'affectedUserEmail:ASCENDING',
          'lifecycleState:ASCENDING',
          'isDeleted:ASCENDING',
          'updatedAt:DESCENDING',
          '__name__:DESCENDING',
        ]),
        _signature('incidentTickets', <String>[
          'assignedToUserId:ASCENDING',
          'lifecycleState:ASCENDING',
          'isDeleted:ASCENDING',
          'updatedAt:DESCENDING',
          '__name__:DESCENDING',
        ]),
        _signature('incidentTickets', <String>[
          'lifecycleState:ASCENDING',
          'isDeleted:ASCENDING',
          'updatedAt:DESCENDING',
          '__name__:DESCENDING',
        ]),
        _signature('incidentTickets', <String>[
          'isDeleted:ASCENDING',
          'updatedAt:DESCENDING',
          '__name__:DESCENDING',
        ]),
        _signature('incidentTickets', <String>[
          'lifecycleState:ASCENDING',
          'isDeleted:ASCENDING',
          'archiveEligibleAt:ASCENDING',
        ]),
        _signature('incidentTickets', <String>[
          'lifecycleState:ASCENDING',
          'slaNextCheckAt:ASCENDING',
          '__name__:ASCENDING',
        ]),
        _signature('comments', <String>[
          'isInternal:ASCENDING',
          'createdAt:DESCENDING',
        ]),
      }),
    );
  });

  test('existing meeting hall index remains in the deployment manifest', () {
    final manifest = jsonDecode(
      File('firestore.indexes.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final signatures = (manifest['indexes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_indexSignature)
        .toSet();

    expect(
      signatures,
      contains(
        _signature('meeting_hall_reservations', <String>[
          'hallId:ASCENDING',
          'startTime:ASCENDING',
          '__name__:ASCENDING',
        ]),
      ),
    );
  });
}

String _indexSignature(Map<String, dynamic> index) {
  final fields = (index['fields'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((field) {
    final mode = field['order'] ?? field['arrayConfig'];
    return '${field['fieldPath']}:$mode';
  });
  return _signature(index['collectionGroup'] as String, fields);
}

String _signature(String collectionGroup, Iterable<String> fields) {
  return '$collectionGroup|${fields.join(',')}';
}
