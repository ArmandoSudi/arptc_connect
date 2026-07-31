import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:flutter_test/flutter_test.dart';

CiRelationship relationship({
  required String id,
  required String source,
  required String target,
  required CiRelationshipType type,
}) =>
    CiRelationship(
      id: id,
      sourceCiId: source,
      sourceCiName: source,
      targetCiId: target,
      targetCiName: target,
      type: type,
      createdAt: DateTime.utc(2026, 7, 31),
      createdByUserId: 'manager-1',
    );

void main() {
  test('preserves relationship direction for dependency and impact views', () {
    final graph = CiRelationshipGraph([
      relationship(
        id: 'rel-1',
        source: 'service',
        target: 'application',
        type: CiRelationshipType.dependsOn,
      ),
      relationship(
        id: 'rel-2',
        source: 'application',
        target: 'server',
        type: CiRelationshipType.runsOn,
      ),
    ]);

    expect(graph.directDependencies('service'), {'application'});
    expect(graph.directDependents('application'), {'service'});
    expect(graph.directDependencies('application'), {'server'});
    expect(graph.directDependents('server'), {'application'});
  });

  test('rejects self relationships', () {
    expect(
      () => relationship(
        id: 'bad',
        source: 'server',
        target: 'server',
        type: CiRelationshipType.connectedTo,
      ),
      throwsArgumentError,
    );
  });
}
