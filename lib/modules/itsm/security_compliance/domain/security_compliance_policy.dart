import '../../shared/domain/itsm_common.dart';
import 'access_review.dart';
import 'asset_compliance.dart';
import 'security_evidence.dart';
import 'security_exception.dart';

/// Pure role and ownership policy mirrored later by routes, repositories,
/// trusted commands, Firestore rules and Storage rules.
abstract final class SecurityComplianceAccessPolicy {
  static bool canReadFinding({required ItsmRole role}) =>
      role == ItsmRole.manager;

  static bool canManageFinding({required ItsmRole role}) =>
      role == ItsmRole.manager;

  static bool canSubmitException({required ItsmRole role}) =>
      role == ItsmRole.user ||
      role == ItsmRole.admin ||
      role == ItsmRole.manager;

  static bool canReadException({
    required ItsmRole role,
    required String actorUserId,
    required SecurityException exception,
  }) =>
      role == ItsmRole.manager || exception.isOwnedBy(actorUserId);

  static bool canManageException({required ItsmRole role}) =>
      role == ItsmRole.manager;

  static bool canReadOperationalEvidence({
    required ItsmRole role,
    required String actorUserId,
    required SecurityEvidenceMetadata evidence,
  }) {
    if (role != ItsmRole.manager) return false;
    return evidence.confidentiality != ItsmConfidentiality.restricted ||
        evidence.authorizedManagerIds.contains(actorUserId.trim());
  }

  static bool canReadComplianceAssessment({required ItsmRole role}) =>
      role == ItsmRole.manager;

  static bool canManageComplianceAssessment({required ItsmRole role}) =>
      role == ItsmRole.manager;

  static bool canReadOwnComplianceProjection({
    required ItsmRole role,
    required String actorUserId,
    required OwnDeviceComplianceProjection projection,
  }) =>
      (role == ItsmRole.user && projection.isOwnedBy(actorUserId)) ||
      role == ItsmRole.manager;

  static bool canReadAccessReviewItem({
    required ItsmRole role,
    required String actorUserId,
    required AccessReviewItem item,
  }) =>
      role == ItsmRole.manager || item.isOwnedBy(actorUserId);

  static bool canManageAccessReviews({required ItsmRole role}) =>
      role == ItsmRole.manager;

  static bool canRequestAccessCorrection({
    required ItsmRole role,
    required String actorUserId,
    required AccessReviewItem item,
    required AccessReviewCampaign campaign,
  }) =>
      campaign.allowSelfServiceCorrection &&
      item.isOwnedBy(actorUserId) &&
      (role == ItsmRole.user || role == ItsmRole.admin);
}
