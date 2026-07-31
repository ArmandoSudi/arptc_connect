import 'change_request.dart';

enum StandardChangeApprovalSemantics {
  preAuthorized,
  enforceSeparationOfDuties,
  allowRequesterApproval,
}

enum ChangeApprovalIssue {
  actorRequired,
  requesterCannotApproveOwnChange,
  emergencyDecisionRequired,
}

class ChangeApprovalValidation {
  ChangeApprovalValidation(Iterable<ChangeApprovalIssue> issues)
      : issues = List<ChangeApprovalIssue>.unmodifiable(issues);

  final List<ChangeApprovalIssue> issues;

  bool get isValid => issues.isEmpty;
}

abstract final class ChangeApprovalPolicy {
  static ChangeApprovalValidation validate({
    required ChangeType changeType,
    required String requesterUserId,
    required String approverUserId,
    StandardChangeApprovalSemantics standardSemantics =
        StandardChangeApprovalSemantics.preAuthorized,
    bool isEmergencyDecision = false,
  }) {
    final issues = <ChangeApprovalIssue>[];
    final requester = requesterUserId.trim();
    final approver = approverUserId.trim();
    if (approver.isEmpty) {
      issues.add(ChangeApprovalIssue.actorRequired);
    }

    final enforceSeparation = changeType != ChangeType.standard ||
        standardSemantics ==
            StandardChangeApprovalSemantics.enforceSeparationOfDuties;
    if (enforceSeparation && requester.isNotEmpty && requester == approver) {
      issues.add(ChangeApprovalIssue.requesterCannotApproveOwnChange);
    }
    if (changeType == ChangeType.emergency && !isEmergencyDecision) {
      issues.add(ChangeApprovalIssue.emergencyDecisionRequired);
    }

    return ChangeApprovalValidation(issues);
  }
}
