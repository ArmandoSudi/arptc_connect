import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical security routes use real Phase 5 screens', () {
    final router = File('lib/router.dart').readAsStringSync();

    expect(router, contains('_buildSecurityComplianceRoute()'));
    expect(router, contains('SecurityFindingsScreen('));
    expect(router, contains('SecurityExceptionsScreen('));
    expect(router, contains('AssetComplianceScreen('));
    expect(router, contains('AccessReviewsScreen('));
    expect(
      RegExp(
        r'_buildItsmSectionRoute\(\s*ItsmSection\.securityCompliance',
      ).hasMatch(router),
      isFalse,
    );
  });
}
