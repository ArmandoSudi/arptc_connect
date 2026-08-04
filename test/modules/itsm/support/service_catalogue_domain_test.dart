import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/support/domain/support_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support_test_fixtures.dart';

void main() {
  group('ServiceCatalogueItem', () {
    test('round-trips all published configuration fields', () {
      final original = fixtureCatalogueItem(
        documents: [
          CatalogueRequiredDocument(
            key: 'approval',
            label: LocalizedValue(en: 'Approval', fr: 'Approbation'),
            allowedContentTypes: const {'application/pdf'},
          ),
        ],
      );

      final restored = ServiceCatalogueItem.fromMap(
        original.id,
        original.toFirestore(),
      );

      expect(restored.code, original.code);
      expect(restored.version, 2);
      expect(restored.name.resolve('fr'), 'Assistance technique');
      expect(restored.workflow.id, 'standard-request');
      expect(restored.workflow.version, 3);
      expect(restored.slaPolicy.version, 4);
      expect(restored.visibleRoles, containsAll(ItsmRole.values));
      expect(restored.requiredDocuments.single.key, 'approval');
      expect(restored.formFields.single.required, isTrue);
      expect(restored.serviceOwner?.teamName, 'Cloud Infrastructure');
      expect(restored.costModel?.resolve('en'), 'Department funded');
      expect(restored.underlyingCis.single.id, 'm365-tenant');
    });

    test('enforces unique dynamic field and document keys', () {
      final field = CatalogueFieldSchema(
        key: 'reason',
        type: CatalogueFieldType.longText,
        label: LocalizedValue(en: 'Reason', fr: 'Raison'),
      );
      expect(
        () => fixtureCatalogueItem(fields: [field, field]),
        throwsArgumentError,
      );
      final document = CatalogueRequiredDocument(
        key: 'proof',
        label: LocalizedValue(en: 'Proof', fr: 'Preuve'),
      );
      expect(
        () => fixtureCatalogueItem(documents: [document, document]),
        throwsArgumentError,
      );
    });

    test('requires versioned workflow and SLA references', () {
      expect(
        () => VersionedConfigurationReference(id: 'workflow', version: 0),
        throwsRangeError,
      );
    });
  });

  group('catalogue eligibility', () {
    test('applies role, organisation, exclusions, and active dates', () {
      final item = fixtureCatalogueItem(
        visibleRoles: const [ItsmRole.user],
        eligibility: CatalogueEligibility(
          allEmployees: false,
          departmentIds: const ['department-1'],
          locationIds: const ['head-office'],
          positionValues: const ['BUREAU_ATTACHE'],
          excludedUserIds: const ['excluded-user'],
        ),
      );
      final allowed = CataloguePrincipal(
        userId: 'user-1',
        role: ItsmRole.user,
        departmentId: 'department-1',
      );
      final wrongRole = CataloguePrincipal(
        userId: 'manager-1',
        role: ItsmRole.manager,
        departmentId: 'department-1',
      );
      final excluded = CataloguePrincipal(
        userId: 'excluded-user',
        role: ItsmRole.user,
        departmentId: 'department-1',
      );

      expect(item.isAvailableTo(allowed, at: fixtureTime), isTrue);
      expect(item.isAvailableTo(wrongRole, at: fixtureTime), isFalse);
      expect(item.isAvailableTo(excluded, at: fixtureTime), isFalse);
    });

    test('matches location and organisation-position entitlement filters', () {
      final item = fixtureCatalogueItem(
        eligibility: CatalogueEligibility(
          allEmployees: false,
          locationIds: const ['head-office'],
          positionValues: const ['BUREAU_ATTACHE'],
        ),
      );
      expect(
        item.isAvailableTo(
          CataloguePrincipal(
            userId: 'user-1',
            role: ItsmRole.user,
            locationId: 'head-office',
          ),
          at: fixtureTime,
        ),
        isTrue,
      );
      expect(
        item.isAvailableTo(
          CataloguePrincipal(
            userId: 'user-2',
            role: ItsmRole.user,
            positionValue: 'BUREAU_ATTACHE',
          ),
          at: fixtureTime,
        ),
        isTrue,
      );
    });

    test('rejects an empty restricted eligibility definition', () {
      expect(
        () => CatalogueEligibility(allEmployees: false),
        throwsArgumentError,
      );
    });
  });

  group('dynamic submission validation', () {
    test('validates required fields, choices, and required documents', () {
      final item = fixtureCatalogueItem(
        fields: [
          CatalogueFieldSchema(
            key: 'urgency',
            type: CatalogueFieldType.singleSelect,
            label: LocalizedValue(en: 'Urgency', fr: 'Urgence'),
            required: true,
            options: [
              CatalogueFieldOption(
                value: 'normal',
                label: LocalizedValue(en: 'Normal', fr: 'Normale'),
              ),
            ],
          ),
        ],
        documents: [
          CatalogueRequiredDocument(
            key: 'approval',
            label: LocalizedValue(en: 'Approval', fr: 'Approbation'),
            allowedContentTypes: const {'application/pdf'},
          ),
        ],
      );
      final principal = CataloguePrincipal(
        userId: 'user-1',
        role: ItsmRole.user,
      );

      final invalid = CatalogueSubmissionValidator.validate(
        item: item,
        principal: principal,
        at: fixtureTime,
        responses: const {'urgency': 'invalid'},
      );
      expect(
        invalid.issues.map((issue) => issue.code),
        containsAll([
          CatalogueSubmissionIssueCode.invalidOption,
          CatalogueSubmissionIssueCode.missingRequiredDocument,
        ]),
      );

      final valid = CatalogueSubmissionValidator.validate(
        item: item,
        principal: principal,
        at: fixtureTime,
        responses: const {'urgency': 'normal'},
        documents: [
          SubmittedDocument(
            requirementKey: 'approval',
            contentType: 'application/pdf',
          ),
        ],
      );
      expect(valid.isValid, isTrue);
    });

    test('rejects unknown fields and unavailable catalogue items', () {
      final principal = CataloguePrincipal(
        userId: 'user-1',
        role: ItsmRole.user,
      );
      final unavailable = CatalogueSubmissionValidator.validate(
        item: fixtureCatalogueItem(status: ItsmPublicationState.draft),
        principal: principal,
        at: fixtureTime,
        responses: const {},
      );
      expect(
        unavailable.issues.single.code,
        CatalogueSubmissionIssueCode.unavailableItem,
      );

      final unknown = CatalogueSubmissionValidator.validate(
        item: fixtureCatalogueItem(),
        principal: principal,
        at: fixtureTime,
        responses: const {
          'title': 'Valid title',
          'unexpected': 'not accepted',
        },
      );
      expect(
        unknown.issues.map((issue) => issue.code),
        contains(CatalogueSubmissionIssueCode.unknownField),
      );
    });
  });

  test('initial catalogue contains every required specification item', () {
    final items = InitialCatalogueDefinitions.build(
      createdAt: fixtureTime,
      createdBy: 'seed-script',
    );
    expect(items, hasLength(14));
    expect(
      items.map((item) => item.code).toSet(),
      InitialCatalogueDefinitions.requiredCodes,
    );
    expect(items.every((item) => item.status == ItsmPublicationState.published),
        isTrue);
    expect(items.every((item) => item.workflow.version == 1), isTrue);
    expect(items.every((item) => item.slaPolicy.version == 1), isTrue);
    expect(
      items.every((item) => item.serviceOwner?.displayName.isNotEmpty == true),
      isTrue,
    );
    expect(items.every((item) => item.fulfilmentSla != null), isTrue);
  });
}
