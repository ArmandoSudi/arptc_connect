import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ITSM navigation catalogue', () {
    test('defines the five required sections', () {
      expect(
        ItsmSection.values,
        const [
          ItsmSection.support,
          ItsmSection.assetsConfiguration,
          ItsmSection.changes,
          ItsmSection.securityCompliance,
          ItsmSection.reportingAdministration,
        ],
      );
      expect(
        ItsmSection.values.map((section) => section.route),
        everyElement(startsWith('/services/itsm/')),
      );
    });

    test('defines all required feature routes under their section', () {
      expect(
        ItsmFeature.incidents.routeFor(ItsmSection.support),
        '/services/itsm/support/incidents',
      );
      expect(
        ItsmFeature.cmdb.routeFor(ItsmSection.assetsConfiguration),
        '/services/itsm/assets-configuration/cmdb',
      );
      expect(
        ItsmRoutes.myAssets,
        '/services/itsm/assets-configuration/assets/my',
      );
      expect(
        ItsmRoutes.myAssetDetail('asset / 42'),
        '/services/itsm/assets-configuration/assets/my/asset%20%2F%2042',
      );
      expect(
        ItsmRoutes.assetRegister,
        '/services/itsm/assets-configuration/assets/register',
      );
      expect(
        ItsmRoutes.assetRegisterDetail('asset / 42'),
        '/services/itsm/assets-configuration/assets/register/asset%20%2F%2042',
      );
      expect(
        ItsmRoutes.stock,
        '/services/itsm/assets-configuration/stock',
      );
      expect(
        ItsmRoutes.licences,
        '/services/itsm/assets-configuration/licences',
      );
      expect(
        ItsmRoutes.suppliersWarranties,
        '/services/itsm/assets-configuration/suppliers-warranties',
      );
      expect(
        ItsmFeature.changeCalendar.routeFor(ItsmSection.changes),
        '/services/itsm/changes/calendar',
      );
      expect(
        ItsmRoutes.changeApprovals,
        '/services/itsm/changes/approvals',
      );
      expect(
        ItsmRoutes.changeRequestDetail('change / 42'),
        '/services/itsm/changes/requests/change%20%2F%2042',
      );
      expect(
        ItsmFeature.accessReviews.routeFor(ItsmSection.securityCompliance),
        '/services/itsm/security-compliance/access-reviews',
      );
      expect(
        ItsmFeature.auditLogs.routeFor(
          ItsmSection.reportingAdministration,
        ),
        '/services/itsm/reporting-administration/audit-logs',
      );
    });
  });

  group('legacy route transformation', () {
    test('redirects all compatibility roots', () {
      expect(
        ItsmRoutes.compatibilityRedirect('/service/incidents'),
        '/services/itsm/support/incidents',
      );
      expect(
        ItsmRoutes.compatibilityRedirect('/service/ticketing'),
        '/services/itsm/support/incidents',
      );
      expect(
        ItsmRoutes.compatibilityRedirect('/service/itsm'),
        '/services/itsm',
      );
    });

    test('preserves nested suffix, query parameters, and fragment', () {
      expect(
        ItsmRoutes.compatibilityRedirect(
          '/service/incidents/manager/INC-42'
          '?source=push&filter=P1#activity',
        ),
        '/services/itsm/support/incidents/manager/INC-42'
        '?source=push&filter=P1#activity',
      );
      expect(
        ItsmRoutes.compatibilityRedirect(
          '/service/itsm/support/knowledge?category=network',
        ),
        '/services/itsm/support/knowledge?category=network',
      );
    });

    test('does not redirect unrelated routes or lookalike prefixes', () {
      expect(ItsmRoutes.compatibilityRedirect('/service/tasks'), isNull);
      expect(
        ItsmRoutes.compatibilityRedirect('/service/incidents-archive'),
        isNull,
      );
    });
  });
}
