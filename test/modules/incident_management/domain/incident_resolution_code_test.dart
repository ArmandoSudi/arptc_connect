import 'package:arptc_connect/modules/incident_management/domain/incident_resolution_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentResolutionCode', () {
    test('normalizes identifiers for stable Firestore values', () {
      expect(
        IncidentResolutionCode.normalizeCode(' workaround provided '),
        'WORKAROUND_PROVIDED',
      );
      expect(
        IncidentResolutionCode.normalizeCode('hardware--replaced'),
        'HARDWARE_REPLACED',
      );
    });

    test('built-in defaults have unique bilingual labels', () {
      const defaults = IncidentResolutionCode.builtInDefaults;
      final uniqueCodes = defaults.map((item) => item.code).toSet();

      expect(uniqueCodes, hasLength(defaults.length));
      for (final resolutionCode in defaults) {
        expect(resolutionCode.code, isNotEmpty);
        expect(resolutionCode.labelForLanguageCode('en'), isNotEmpty);
        expect(resolutionCode.labelForLanguageCode('fr'), isNotEmpty);
      }
    });
  });
}
