import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/collaboration.dart';
import '../../shared/domain/itsm_common.dart';

enum ChangeCollaborationScope { requesterVisible, operational }

class ChangeCollaborationReadDecision {
  const ChangeCollaborationReadDecision._({
    required this.scope,
    required this.requiresRequesterOwnership,
  });

  factory ChangeCollaborationReadDecision.forPrincipal(
    ItsmQueryPrincipal principal,
  ) {
    if (principal.role == ItsmRole.manager) {
      return const ChangeCollaborationReadDecision._(
        scope: ChangeCollaborationScope.operational,
        requiresRequesterOwnership: false,
      );
    }
    return const ChangeCollaborationReadDecision._(
      scope: ChangeCollaborationScope.requesterVisible,
      requiresRequesterOwnership: true,
    );
  }

  final ChangeCollaborationScope scope;
  final bool requiresRequesterOwnership;

  bool get requiresRequesterVisibilityQuery =>
      scope == ChangeCollaborationScope.requesterVisible;

  bool allowsComment(ItsmCommentVisibility visibility) => switch (scope) {
        ChangeCollaborationScope.requesterVisible =>
          visibility == ItsmCommentVisibility.requesterVisible,
        ChangeCollaborationScope.operational =>
          visibility != ItsmCommentVisibility.restricted,
      };

  bool allowsAttachment(ItsmAttachmentVisibility visibility) => switch (scope) {
        ChangeCollaborationScope.requesterVisible =>
          visibility == ItsmAttachmentVisibility.requesterVisible,
        ChangeCollaborationScope.operational =>
          visibility != ItsmAttachmentVisibility.restricted,
      };

  bool allowsAudit(Map<String, Object?> data) {
    final action =
        (data['action'] ?? data['eventType'])?.toString().trim().toLowerCase();
    if (action?.contains('cab_meeting') == true) return false;
    if (scope == ChangeCollaborationScope.operational) return true;
    return data['isInternal'] == false && data['requesterVisible'] != false;
  }
}
