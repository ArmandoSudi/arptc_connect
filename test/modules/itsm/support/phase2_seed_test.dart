import 'dart:convert';
import 'dart:io';

import 'package:arptc_connect/modules/itsm/support/domain/initial_catalogue_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 2 seed provisions every initial item and pinned dependency', () {
    final seed = jsonDecode(
      File('tool/seeds/itsm_phase2_seed.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final documents =
        (seed['documents'] as List<dynamic>).cast<Map<String, dynamic>>();
    final byPath = {
      for (final document in documents)
        document['path'] as String: document['data'] as Map<String, dynamic>,
    };
    final cataloguePaths = byPath.keys
        .where((path) => path.startsWith('serviceCatalogItems/'))
        .toList(growable: false);

    expect(
      cataloguePaths.map((path) => path.split('/').last).toSet(),
      InitialCatalogueDefinitions.requiredCodes,
    );
    for (final path in cataloguePaths) {
      final item = byPath[path]!;
      final workflow = item['workflow'] as Map<String, dynamic>;
      final slaPolicy = item['slaPolicy'] as Map<String, dynamic>;
      expect(byPath, contains('workflowDefinitions/${workflow['id']}'));
      expect(
        byPath,
        contains(
          'workflowDefinitions/${workflow['id']}/versions/'
          '${_versionId(workflow['version'] as int)}',
        ),
      );
      expect(byPath, contains('slaPolicies/${slaPolicy['id']}'));
      expect(
        byPath,
        contains(
          'slaPolicies/${slaPolicy['id']}/versions/'
          '${_versionId(slaPolicy['version'] as int)}',
        ),
      );
    }
  });
}

String _versionId(int version) => version.toString().padLeft(6, '0');
