import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';

enum ItsmRouteRequirement {
  automatic,
  selfService,
  operational,
  executive,
  operationalOrExecutive,
}

abstract final class ItsmRouteAccessPolicy {
  static const _managerOnlyFeatures = {
    ItsmFeature.stock,
    ItsmFeature.licences,
    ItsmFeature.suppliersWarranties,
    ItsmFeature.cmdb,
    ItsmFeature.approvalsCab,
    ItsmFeature.securityFindings,
  };

  static bool canAccess({
    required ItsmRole role,
    ItsmSection? section,
    ItsmFeature? feature,
    ItsmRouteRequirement requirement = ItsmRouteRequirement.automatic,
  }) {
    switch (requirement) {
      case ItsmRouteRequirement.selfService:
        return true;
      case ItsmRouteRequirement.operational:
        return role == ItsmRole.manager;
      case ItsmRouteRequirement.executive:
        return role == ItsmRole.admin;
      case ItsmRouteRequirement.operationalOrExecutive:
        return role == ItsmRole.manager || role == ItsmRole.admin;
      case ItsmRouteRequirement.automatic:
        break;
    }

    if (section == ItsmSection.reportingAdministration) {
      return role == ItsmRole.manager || role == ItsmRole.admin;
    }
    if (feature != null && _managerOnlyFeatures.contains(feature)) {
      return role == ItsmRole.manager;
    }
    return true;
  }

  static bool isReadOnly({
    required ItsmRole role,
    ItsmSection? section,
    ItsmRouteRequirement requirement = ItsmRouteRequirement.automatic,
  }) {
    if (role != ItsmRole.admin) {
      return false;
    }
    return section == ItsmSection.reportingAdministration ||
        requirement == ItsmRouteRequirement.executive ||
        requirement == ItsmRouteRequirement.operationalOrExecutive;
  }
}
