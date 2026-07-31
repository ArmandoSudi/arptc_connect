import 'package:arptc_connect/modules/service/module_config.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ITSM module registration', () {
    test('replaces the product-facing incident module card', () {
      final itsmModules = ModulesConfig.allModules
          .where((module) => module.module == AppModule.itsm)
          .toList();

      expect(itsmModules, hasLength(1));
      expect(itsmModules.single.name, 'IT Service Management');
      expect(
        ModulesConfig.allModules
            .where((module) => module.module.permissionKey == 'ticketing'),
        hasLength(1),
      );
      expect(
        ModulesConfig.allModules
            .where((module) => module.module.routeSegment == 'incidents'),
        isEmpty,
      );
    });

    test('uses canonical navigation and the existing stored permission key',
        () {
      expect(AppModule.itsm.routePath, '/services/itsm');
      expect(AppModule.itsm.routeSegment, 'itsm');
      expect(AppModule.itsm.permissionKey, 'ticketing');
      expect(Modules.emptyPermissions(), contains('ticketing'));
      expect(Modules.emptyPermissions(), isNot(contains('itsm')));
    });

    test('normalizes historical and product-facing aliases to ticketing', () {
      const aliases = [
        'itsm',
        'IT Service Management',
        'it_service_mgmt',
        'service-management',
        'support',
        'it_support',
        'incident',
        'incidents',
        'incident_management',
        'ticket',
        'ticketing',
      ];

      for (final alias in aliases) {
        expect(
          Modules.normalizeModuleKey(alias),
          'ticketing',
          reason: '$alias must resolve existing Firestore permissions',
        );
      }
    });
  });
}
