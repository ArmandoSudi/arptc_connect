import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Asset Configuration manifest covers every supported filtered list', () {
    final signatures = _indexSignatures();

    for (final fields in _combinations(
      const ['status', 'categoryId', 'locationId'],
    )) {
      _expectIndex(signatures, 'assets', [...fields, 'updatedAt', '__name__']);
      _expectIndex(
        signatures,
        'assets',
        [...fields, 'searchTokens[]', 'updatedAt', '__name__'],
      );
    }

    for (final fields in _combinations(
      const ['locationId', 'isLowStock', 'kind'],
    )) {
      _expectIndex(
        signatures,
        'stockItems',
        [...fields, 'updatedAt', '__name__'],
      );
    }

    for (final fields in _combinations(
      const [
        'ciType',
        'operationalStatus',
        'criticality',
        'supportGroupId',
      ],
    )) {
      _expectIndex(
        signatures,
        'configurationItems',
        [...fields, 'updatedAt', '__name__'],
      );
    }

    for (final expected in const <_ExpectedIndex>[
      _ExpectedIndex(
        'assetSelfServiceProjections',
        ['assignedUserId', 'isCurrent', 'updatedAt', '__name__'],
      ),
      _ExpectedIndex(
        'assetSelfServiceProjections',
        ['assignedUserId', 'assetId', 'isCurrent', 'updatedAt', '__name__'],
      ),
      _ExpectedIndex(
        'assetAssignments',
        ['assetId', 'assignedAt', '__name__'],
      ),
      _ExpectedIndex(
        'assetAssignments',
        ['assignedUserId', 'status', 'assignedAt', '__name__'],
      ),
      _ExpectedIndex(
        'assetLifecycleEvents',
        ['assetId', 'occurredAt', '__name__'],
      ),
      _ExpectedIndex(
        'assetStateEvents',
        ['assetId', 'changedAt', '__name__'],
      ),
      _ExpectedIndex(
        'softwareLicences',
        ['complianceStatus', 'vendor', 'updatedAt', '__name__'],
      ),
      _ExpectedIndex(
        'softwareLicences',
        ['complianceStatus', 'vendor', 'expiryDate', '__name__'],
      ),
      _ExpectedIndex('suppliers', ['isActive', 'updatedAt', '__name__']),
      _ExpectedIndex(
        'supplierContracts',
        ['supplierId', 'status', 'updatedAt', '__name__'],
      ),
      _ExpectedIndex(
        'warranties',
        ['supplierId', 'expirationDate', '__name__'],
      ),
      _ExpectedIndex(
        'ciRelationships',
        ['sourceEntityId', 'createdAt', '__name__'],
      ),
      _ExpectedIndex(
        'ciRelationships',
        ['targetEntityId', 'createdAt', '__name__'],
      ),
    ]) {
      _expectIndex(signatures, expected.collectionGroup, expected.fields);
    }
  });
}

Set<String> _indexSignatures() {
  final manifest = jsonDecode(
    File('firestore.indexes.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (manifest['indexes'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((index) {
    final fields = (index['fields'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((field) {
      final suffix = field['arrayConfig'] == 'CONTAINS' ? '[]' : '';
      return '${field['fieldPath']}$suffix';
    });
    return '${index['collectionGroup']}|${fields.join(',')}';
  }).toSet();
}

Iterable<List<String>> _combinations(List<String> fields) sync* {
  for (var mask = 1; mask < 1 << fields.length; mask++) {
    yield [
      for (var index = 0; index < fields.length; index++)
        if ((mask & (1 << index)) != 0) fields[index],
    ];
  }
}

void _expectIndex(
  Set<String> signatures,
  String collectionGroup,
  List<String> fields,
) {
  expect(signatures, contains('$collectionGroup|${fields.join(',')}'));
}

class _ExpectedIndex {
  const _ExpectedIndex(this.collectionGroup, this.fields);

  final String collectionGroup;
  final List<String> fields;
}
