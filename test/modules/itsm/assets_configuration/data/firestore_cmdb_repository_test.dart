import 'package:arptc_connect/modules/itsm/assets_configuration/data/firestore_cmdb_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CMDB repositories query canonical trusted Function field names', () {
    expect(CmdbFirestoreFields.itemType, 'ciType');
    expect(CmdbFirestoreFields.relationshipSource, 'sourceEntityId');
    expect(CmdbFirestoreFields.relationshipTarget, 'targetEntityId');

    expect(CmdbFirestoreFields.itemType, isNot('type'));
    expect(CmdbFirestoreFields.relationshipSource, isNot('sourceCiId'));
    expect(CmdbFirestoreFields.relationshipTarget, isNot('targetCiId'));
  });
}
