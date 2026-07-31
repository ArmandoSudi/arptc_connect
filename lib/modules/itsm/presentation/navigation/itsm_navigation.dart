import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class ItsmRoutes {
  static const root = '/services/itsm';
  static const support = '$root/support';
  static const incidents = '$support/incidents';
  static const serviceRequests = '$support/service-requests';
  static const myRequests = '$support/my-requests';
  static const knowledge = '$support/knowledge';
  static const assetsConfiguration = '$root/assets-configuration';
  static const assets = '$assetsConfiguration/assets';
  static const myAssets = '$assets/my';
  static const assetRegister = '$assets/register';
  static const stock = '$assetsConfiguration/stock';
  static const licences = '$assetsConfiguration/licences';
  static const suppliersWarranties =
      '$assetsConfiguration/suppliers-warranties';
  static const cmdb = '$assetsConfiguration/cmdb';
  static const changes = '$root/changes';
  static const changeRequests = '$changes/requests';
  static const changeApprovals = '$changes/approvals';
  static const changeCalendar = '$changes/calendar';
  static const securityCompliance = '$root/security-compliance';
  static const reportingAdministration = '$root/reporting-administration';

  static String myAssetDetail(String assetId) =>
      '$myAssets/${Uri.encodeComponent(assetId)}';

  static String assetRegisterDetail(String assetId) =>
      '$assetRegister/${Uri.encodeComponent(assetId)}';

  static String changeRequestDetail(String changeId) =>
      '$changeRequests/${Uri.encodeComponent(changeId)}';

  static const _legacyPrefixes = <String, String>{
    '/service/itsm': root,
    '/service/incidents': incidents,
    '/service/ticketing': incidents,
  };

  /// Returns a canonical ITSM location for a legacy route.
  ///
  /// The unmatched path suffix, query parameters, and fragment are retained.
  /// A null result means [location] is not an ITSM compatibility route.
  static String? compatibilityRedirect(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null) {
      return null;
    }

    for (final entry in _legacyPrefixes.entries) {
      final legacyPrefix = entry.key;
      if (uri.path != legacyPrefix && !uri.path.startsWith('$legacyPrefix/')) {
        continue;
      }
      final suffix = uri.path.substring(legacyPrefix.length);
      return uri.replace(path: '${entry.value}$suffix').toString();
    }

    return null;
  }
}

List<GoRoute> buildItsmCompatibilityRoutes() {
  return [
    for (final segment in const ['incidents', 'ticketing', 'itsm']) ...[
      GoRoute(
        path: segment,
        redirect: _redirectCompatibilityLocation,
      ),
      GoRoute(
        path: '$segment/:legacyPath(.*)',
        redirect: _redirectCompatibilityLocation,
      ),
    ],
  ];
}

String? _redirectCompatibilityLocation(
  BuildContext context,
  GoRouterState state,
) {
  return ItsmRoutes.compatibilityRedirect(state.location);
}

enum ItsmSection {
  support,
  assetsConfiguration,
  changes,
  securityCompliance,
  reportingAdministration,
}

extension ItsmSectionPresentation on ItsmSection {
  String get route {
    switch (this) {
      case ItsmSection.support:
        return ItsmRoutes.support;
      case ItsmSection.assetsConfiguration:
        return ItsmRoutes.assetsConfiguration;
      case ItsmSection.changes:
        return ItsmRoutes.changes;
      case ItsmSection.securityCompliance:
        return ItsmRoutes.securityCompliance;
      case ItsmSection.reportingAdministration:
        return ItsmRoutes.reportingAdministration;
    }
  }

  IconData get icon {
    switch (this) {
      case ItsmSection.support:
        return Icons.support_agent_rounded;
      case ItsmSection.assetsConfiguration:
        return Icons.devices_other_rounded;
      case ItsmSection.changes:
        return Icons.change_circle_outlined;
      case ItsmSection.securityCompliance:
        return Icons.security_rounded;
      case ItsmSection.reportingAdministration:
        return Icons.analytics_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ItsmSection.support:
        return const Color(0xFF155EEF);
      case ItsmSection.assetsConfiguration:
        return const Color(0xFF008A8A);
      case ItsmSection.changes:
        return const Color(0xFF7C3AED);
      case ItsmSection.securityCompliance:
        return const Color(0xFFD92D20);
      case ItsmSection.reportingAdministration:
        return const Color(0xFFF79009);
    }
  }

  String title(S l10n) {
    switch (this) {
      case ItsmSection.support:
        return l10n.itsmSupport;
      case ItsmSection.assetsConfiguration:
        return l10n.itsmAssetsConfiguration;
      case ItsmSection.changes:
        return l10n.itsmChanges;
      case ItsmSection.securityCompliance:
        return l10n.itsmSecurityCompliance;
      case ItsmSection.reportingAdministration:
        return l10n.itsmReportingAdministration;
    }
  }

  String description(S l10n) {
    switch (this) {
      case ItsmSection.support:
        return l10n.itsmSupportDescription;
      case ItsmSection.assetsConfiguration:
        return l10n.itsmAssetsConfigurationDescription;
      case ItsmSection.changes:
        return l10n.itsmChangesDescription;
      case ItsmSection.securityCompliance:
        return l10n.itsmSecurityComplianceDescription;
      case ItsmSection.reportingAdministration:
        return l10n.itsmReportingAdministrationDescription;
    }
  }

  List<ItsmFeature> get features {
    switch (this) {
      case ItsmSection.support:
        return const [
          ItsmFeature.incidents,
          ItsmFeature.serviceRequests,
          ItsmFeature.myRequests,
          ItsmFeature.knowledgeBase,
        ];
      case ItsmSection.assetsConfiguration:
        return const [
          ItsmFeature.assets,
          ItsmFeature.stock,
          ItsmFeature.licences,
          ItsmFeature.suppliersWarranties,
          ItsmFeature.cmdb,
        ];
      case ItsmSection.changes:
        return const [
          ItsmFeature.changeRequests,
          ItsmFeature.approvalsCab,
          ItsmFeature.changeCalendar,
        ];
      case ItsmSection.securityCompliance:
        return const [
          ItsmFeature.securityFindings,
          ItsmFeature.securityExceptions,
          ItsmFeature.assetCompliance,
          ItsmFeature.accessReviews,
        ];
      case ItsmSection.reportingAdministration:
        return const [
          ItsmFeature.dashboards,
          ItsmFeature.sla,
          ItsmFeature.serviceCatalogue,
          ItsmFeature.workflowConfiguration,
          ItsmFeature.auditLogs,
        ];
    }
  }
}

enum ItsmFeature {
  incidents,
  serviceRequests,
  myRequests,
  knowledgeBase,
  assets,
  stock,
  licences,
  suppliersWarranties,
  cmdb,
  changeRequests,
  approvalsCab,
  changeCalendar,
  securityFindings,
  securityExceptions,
  assetCompliance,
  accessReviews,
  dashboards,
  sla,
  serviceCatalogue,
  workflowConfiguration,
  auditLogs,
}

extension ItsmFeaturePresentation on ItsmFeature {
  String get routeSegment {
    switch (this) {
      case ItsmFeature.incidents:
        return 'incidents';
      case ItsmFeature.serviceRequests:
        return 'service-requests';
      case ItsmFeature.myRequests:
        return 'my-requests';
      case ItsmFeature.knowledgeBase:
        return 'knowledge';
      case ItsmFeature.assets:
        return 'assets';
      case ItsmFeature.stock:
        return 'stock';
      case ItsmFeature.licences:
        return 'licences';
      case ItsmFeature.suppliersWarranties:
        return 'suppliers-warranties';
      case ItsmFeature.cmdb:
        return 'cmdb';
      case ItsmFeature.changeRequests:
        return 'requests';
      case ItsmFeature.approvalsCab:
        return 'approvals';
      case ItsmFeature.changeCalendar:
        return 'calendar';
      case ItsmFeature.securityFindings:
        return 'findings';
      case ItsmFeature.securityExceptions:
        return 'exceptions';
      case ItsmFeature.assetCompliance:
        return 'asset-compliance';
      case ItsmFeature.accessReviews:
        return 'access-reviews';
      case ItsmFeature.dashboards:
        return 'dashboards';
      case ItsmFeature.sla:
        return 'sla';
      case ItsmFeature.serviceCatalogue:
        return 'service-catalogue';
      case ItsmFeature.workflowConfiguration:
        return 'workflows';
      case ItsmFeature.auditLogs:
        return 'audit-logs';
    }
  }

  String routeFor(ItsmSection section) => '${section.route}/$routeSegment';

  IconData get icon {
    switch (this) {
      case ItsmFeature.incidents:
        return Icons.confirmation_number_outlined;
      case ItsmFeature.serviceRequests:
        return Icons.assignment_outlined;
      case ItsmFeature.myRequests:
        return Icons.person_search_outlined;
      case ItsmFeature.knowledgeBase:
        return Icons.menu_book_outlined;
      case ItsmFeature.assets:
        return Icons.computer_outlined;
      case ItsmFeature.stock:
        return Icons.inventory_2_outlined;
      case ItsmFeature.licences:
        return Icons.key_outlined;
      case ItsmFeature.suppliersWarranties:
        return Icons.handshake_outlined;
      case ItsmFeature.cmdb:
        return Icons.account_tree_outlined;
      case ItsmFeature.changeRequests:
        return Icons.change_circle_outlined;
      case ItsmFeature.approvalsCab:
        return Icons.fact_check_outlined;
      case ItsmFeature.changeCalendar:
        return Icons.calendar_month_outlined;
      case ItsmFeature.securityFindings:
        return Icons.policy_outlined;
      case ItsmFeature.securityExceptions:
        return Icons.gpp_maybe_outlined;
      case ItsmFeature.assetCompliance:
        return Icons.verified_user_outlined;
      case ItsmFeature.accessReviews:
        return Icons.manage_accounts_outlined;
      case ItsmFeature.dashboards:
        return Icons.dashboard_outlined;
      case ItsmFeature.sla:
        return Icons.timer_outlined;
      case ItsmFeature.serviceCatalogue:
        return Icons.view_list_outlined;
      case ItsmFeature.workflowConfiguration:
        return Icons.schema_outlined;
      case ItsmFeature.auditLogs:
        return Icons.history_outlined;
    }
  }

  String title(S l10n) {
    switch (this) {
      case ItsmFeature.incidents:
        return l10n.itsmIncidents;
      case ItsmFeature.serviceRequests:
        return l10n.itsmServiceRequests;
      case ItsmFeature.myRequests:
        return l10n.itsmMyRequests;
      case ItsmFeature.knowledgeBase:
        return l10n.itsmKnowledgeBase;
      case ItsmFeature.assets:
        return l10n.itsmAssets;
      case ItsmFeature.stock:
        return l10n.itsmStock;
      case ItsmFeature.licences:
        return l10n.itsmLicences;
      case ItsmFeature.suppliersWarranties:
        return l10n.itsmSuppliersWarranties;
      case ItsmFeature.cmdb:
        return l10n.itsmCmdb;
      case ItsmFeature.changeRequests:
        return l10n.itsmChangeRequests;
      case ItsmFeature.approvalsCab:
        return l10n.itsmApprovalsCab;
      case ItsmFeature.changeCalendar:
        return l10n.itsmChangeCalendar;
      case ItsmFeature.securityFindings:
        return l10n.itsmSecurityFindings;
      case ItsmFeature.securityExceptions:
        return l10n.itsmSecurityExceptions;
      case ItsmFeature.assetCompliance:
        return l10n.itsmAssetCompliance;
      case ItsmFeature.accessReviews:
        return l10n.itsmAccessReviews;
      case ItsmFeature.dashboards:
        return l10n.itsmDashboards;
      case ItsmFeature.sla:
        return l10n.itsmSla;
      case ItsmFeature.serviceCatalogue:
        return l10n.itsmServiceCatalogue;
      case ItsmFeature.workflowConfiguration:
        return l10n.itsmWorkflowConfiguration;
      case ItsmFeature.auditLogs:
        return l10n.itsmAuditLogs;
    }
  }
}
