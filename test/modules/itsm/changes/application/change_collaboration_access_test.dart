import 'package:arptc_connect/modules/itsm/changes/application/change_collaboration_access.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('change collaboration visibility', () {
    test('MANAGER receives operational but not restricted collaboration', () {
      final decision = ChangeCollaborationReadDecision.forPrincipal(
        _principal(ItsmRole.manager),
      );

      expect(decision.scope, ChangeCollaborationScope.operational);
      expect(decision.requiresRequesterOwnership, isFalse);
      expect(decision.allowsComment(ItsmCommentVisibility.internal), isTrue);
      expect(
        decision.allowsAttachment(ItsmAttachmentVisibility.requesterVisible),
        isTrue,
      );
      expect(
        decision.allowsComment(ItsmCommentVisibility.restricted),
        isFalse,
      );
    });

    for (final role in [ItsmRole.user, ItsmRole.admin]) {
      test('$role receives requester-visible collaboration on own parent only',
          () {
        final decision = ChangeCollaborationReadDecision.forPrincipal(
          _principal(role),
        );

        expect(decision.scope, ChangeCollaborationScope.requesterVisible);
        expect(decision.requiresRequesterOwnership, isTrue);
        expect(decision.requiresRequesterVisibilityQuery, isTrue);
        expect(
          decision.allowsComment(ItsmCommentVisibility.requesterVisible),
          isTrue,
        );
        expect(
          decision.allowsAttachment(ItsmAttachmentVisibility.internal),
          isFalse,
        );
      });
    }

    test('CAB deliberations never enter the activity read model', () {
      final manager = ChangeCollaborationReadDecision.forPrincipal(
        _principal(ItsmRole.manager),
      );
      final requester = ChangeCollaborationReadDecision.forPrincipal(
        _principal(ItsmRole.user),
      );

      const cabEvent = <String, Object?>{
        'action': 'cab_meeting_updated',
        'isInternal': false,
      };
      expect(manager.allowsAudit(cabEvent), isFalse);
      expect(requester.allowsAudit(cabEvent), isFalse);
      expect(
        requester.allowsAudit(const {
          'action': 'scheduled',
          'isInternal': false,
        }),
        isTrue,
      );
    });
  });
}

ItsmQueryPrincipal _principal(ItsmRole role) => ItsmQueryPrincipal(
      sessionKey: 'user-1|agent@example.com',
      userId: 'user-1',
      email: 'agent@example.com',
      role: role,
    );
