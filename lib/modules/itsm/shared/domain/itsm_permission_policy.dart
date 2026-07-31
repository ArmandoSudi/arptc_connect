import 'itsm_common.dart';

class ItsmPermissionPolicy {
  const ItsmPermissionPolicy(this.role);

  final ItsmRole role;

  bool get canUseSelfService => true;
  bool get canCreateSelfServiceRecord => true;
  bool get canOperate => role == ItsmRole.manager;
  bool get canManageConfiguration => role == ItsmRole.manager;
  bool get canReadExecutiveReporting => role == ItsmRole.admin;
  bool get isExecutiveReadOnly => role == ItsmRole.admin;

  bool canReadWorkItem({
    required String currentUserId,
    required String requesterUserId,
    ItsmConfidentiality confidentiality = ItsmConfidentiality.internal,
  }) {
    if (role == ItsmRole.manager) return true;

    final ownsRecord = currentUserId.trim().isNotEmpty &&
        currentUserId.trim() == requesterUserId.trim();
    if (!ownsRecord) return false;

    // Restricted self-service records, such as security exceptions, remain
    // visible to their requester while organisation-wide access stays denied.
    return confidentiality != ItsmConfidentiality.restricted || ownsRecord;
  }

  bool canMutateOperationalFields({
    required String currentUserId,
    required String requesterUserId,
  }) {
    return role == ItsmRole.manager;
  }

  bool canCancelOwnRecord({
    required String currentUserId,
    required String requesterUserId,
    required bool workflowAllowsCancellation,
  }) {
    if (!workflowAllowsCancellation) return false;
    if (role == ItsmRole.manager) return true;
    return currentUserId.trim().isNotEmpty &&
        currentUserId.trim() == requesterUserId.trim();
  }
}
