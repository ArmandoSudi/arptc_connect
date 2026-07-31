import '../../shared/domain/itsm_common.dart';
import '../application/security_compliance_access.dart';
import 'security_compliance_repository.dart';

class SecurityComplianceQueryShape {
  const SecurityComplianceQueryShape({
    required this.collection,
    required this.equalityFields,
    required this.orderFields,
    this.collectionGroup = false,
  });

  final String collection;
  final bool collectionGroup;
  final List<String> equalityFields;
  final List<String> orderFields;
}

/// Canonical Firestore collection and index contract for Phase 5 reads.
abstract final class SecurityComplianceQueryContract {
  static const findingsCollection = 'securityFindings';
  static const exceptionsCollection = 'securityExceptions';
  static const assessmentsCollection = 'assetComplianceAssessments';
  static const selfServiceComplianceCollection = 'assetComplianceSelfService';
  static const campaignsCollection = 'accessReviewCampaigns';
  static const reviewItemsCollection = 'accessReviewItems';
  static const correctionsCollectionGroup = 'correctionRequests';

  static const updatedOrder = ['updatedAt desc', '__name__ desc'];
  static const createdOrder = ['createdAt desc', '__name__ desc'];

  static SecurityComplianceQueryShape findings(
    SecurityComplianceQuery query,
  ) =>
      SecurityComplianceQueryShape(
        collection: findingsCollection,
        equalityFields: _optionalFilter(query, 'status', 'severity'),
        orderFields: updatedOrder,
      );

  static SecurityComplianceQueryShape exceptions(
    SecurityComplianceQuery query,
  ) =>
      SecurityComplianceQueryShape(
        collection: exceptionsCollection,
        equalityFields: [
          if (query.scope == SecurityComplianceScope.selfService) ...[
            'requester.userId',
            'selfServiceVisible',
          ],
          ..._optionalFilter(query, 'status', 'affectedServiceId'),
        ],
        orderFields: updatedOrder,
      );

  static SecurityComplianceQueryShape assessments(
    SecurityComplianceQuery query,
  ) =>
      SecurityComplianceQueryShape(
        collection: assessmentsCollection,
        equalityFields: _optionalFilter(query, 'result', 'assignedUserId'),
        orderFields: updatedOrder,
      );

  static const ownCompliance = SecurityComplianceQueryShape(
    collection: selfServiceComplianceCollection,
    equalityFields: ['assignedUserId'],
    orderFields: updatedOrder,
  );

  static SecurityComplianceQueryShape campaigns(
    SecurityComplianceQuery query,
  ) =>
      SecurityComplianceQueryShape(
        collection: campaignsCollection,
        equalityFields: _optionalFilter(query, 'status', null),
        orderFields: updatedOrder,
      );

  static SecurityComplianceQueryShape reviewItems(
    SecurityComplianceQuery query,
  ) =>
      SecurityComplianceQueryShape(
        collection: reviewItemsCollection,
        equalityFields: [
          if (query.scope == SecurityComplianceScope.selfService) ...[
            'subjectUser.userId',
            'selfServiceVisible',
          ],
          ..._optionalFilter(query, 'completionStatus', 'campaignId'),
        ],
        orderFields: updatedOrder,
      );

  static SecurityComplianceQueryShape corrections(ItsmRole role) =>
      SecurityComplianceQueryShape(
        collection: correctionsCollectionGroup,
        collectionGroup: true,
        equalityFields: role == ItsmRole.manager ? const [] : ['requestedBy'],
        orderFields: createdOrder,
      );

  static List<String> _optionalFilter(
    SecurityComplianceQuery query,
    String statusField,
    String? secondaryField,
  ) {
    if (query.status?.trim().isNotEmpty ?? false) return [statusField];
    if (secondaryField != null &&
        (query.secondaryFilter?.trim().isNotEmpty ?? false)) {
      return [secondaryField];
    }
    return const [];
  }
}
