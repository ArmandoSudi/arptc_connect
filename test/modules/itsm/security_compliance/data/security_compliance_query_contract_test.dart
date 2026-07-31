import 'package:arptc_connect/modules/itsm/security_compliance/application/security_compliance_access.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/data/security_compliance_data.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityComplianceQueryContract', () {
    test('uses canonical collections and bounded deterministic ordering', () {
      expect(
        SecurityComplianceQueryContract.selfServiceComplianceCollection,
        'assetComplianceSelfService',
      );
      expect(
        SecurityComplianceQueryContract.correctionsCollectionGroup,
        'correctionRequests',
      );
      expect(
        SecurityComplianceQueryContract.updatedOrder,
        ['updatedAt desc', '__name__ desc'],
      );
    });

    test('self-service exception proves ownership and visibility', () {
      final shape = SecurityComplianceQueryContract.exceptions(
        const SecurityComplianceQuery(
          scope: SecurityComplianceScope.selfService,
          status: 'active',
        ),
      );
      expect(
        shape.equalityFields,
        ['requester.userId', 'selfServiceVisible', 'status'],
      );
      expect(shape.orderFields, SecurityComplianceQueryContract.updatedOrder);
    });

    test('self-service review proves subject ownership and visibility', () {
      final shape = SecurityComplianceQueryContract.reviewItems(
        const SecurityComplianceQuery(
          scope: SecurityComplianceScope.selfService,
          secondaryFilter: 'campaign-1',
        ),
      );
      expect(
        shape.equalityFields,
        ['subjectUser.userId', 'selfServiceVisible', 'campaignId'],
      );
    });

    test('findings are MANAGER metadata with one optional indexed filter', () {
      final shape = SecurityComplianceQueryContract.findings(
        const SecurityComplianceQuery(
          scope: SecurityComplianceScope.operational,
          secondaryFilter: 'critical',
        ),
      );
      expect(shape.collection, 'securityFindings');
      expect(shape.equalityFields, ['severity']);
      expect(shape.orderFields, SecurityComplianceQueryContract.updatedOrder);
    });

    test('corrections use collection group and requester isolation', () {
      final selfService = SecurityComplianceQueryContract.corrections(
        ItsmRole.user,
      );
      expect(selfService.collectionGroup, isTrue);
      expect(selfService.equalityFields, ['requestedBy']);
      expect(
        SecurityComplianceQueryContract.corrections(ItsmRole.manager)
            .equalityFields,
        isEmpty,
      );
    });

    test('remaining operational shapes declare exact composite dimensions', () {
      final assessment = SecurityComplianceQueryContract.assessments(
        const SecurityComplianceQuery(
          scope: SecurityComplianceScope.operational,
          status: 'non_compliant',
        ),
      );
      expect(assessment.equalityFields, ['result']);

      const ownCompliance = SecurityComplianceQueryContract.ownCompliance;
      expect(ownCompliance.equalityFields, ['assignedUserId']);
      expect(ownCompliance.orderFields, ['updatedAt desc', '__name__ desc']);

      final campaign = SecurityComplianceQueryContract.campaigns(
        const SecurityComplianceQuery(
          scope: SecurityComplianceScope.operational,
          status: 'active',
        ),
      );
      expect(campaign.equalityFields, ['status']);

      final operationalReview = SecurityComplianceQueryContract.reviewItems(
        const SecurityComplianceQuery(
          scope: SecurityComplianceScope.operational,
          status: 'pending',
        ),
      );
      expect(operationalReview.equalityFields, ['completionStatus']);
    });

    test('query rejects status and secondary filters together', () {
      expect(
        () => SecurityComplianceQuery(
          scope: SecurityComplianceScope.operational,
          status: 'active',
          secondaryFilter: 'critical',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
