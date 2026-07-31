import 'package:arptc_connect/modules/itsm/security_compliance/data/security_compliance_evidence_sanitizer.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final evidence = [
    {'id': 'internal', 'confidentiality': 'internal'},
    {
      'id': 'allowed',
      'confidentiality': 'restricted',
      'authorizedManagerIds': ['manager-1'],
    },
    {
      'id': 'denied',
      'confidentiality': 'restricted',
      'authorizedManagerIds': ['manager-2'],
    },
  ];

  test('removes every evidence item from USER and ADMIN projections', () {
    for (final role in [ItsmRole.user, ItsmRole.admin]) {
      final result = SecurityComplianceEvidenceSanitizer.sanitize(
        {'evidence': evidence},
        _principal(role, 'user-1'),
      );
      expect(result['evidence'], isEmpty);
    }
  });

  test('MANAGER sees internal and explicitly authorized restricted evidence',
      () {
    final result = SecurityComplianceEvidenceSanitizer.sanitize(
      {'evidence': evidence},
      _principal(ItsmRole.manager, 'manager-1'),
    );
    final ids = (result['evidence']! as Iterable)
        .map((item) => (item as Map)['id'])
        .toList();
    expect(ids, ['internal', 'allowed']);
  });
}

ItsmQueryPrincipal _principal(ItsmRole role, String userId) =>
    ItsmQueryPrincipal(
      sessionKey: '$userId|test@example.com',
      userId: userId,
      email: 'test@example.com',
      role: role,
    );
