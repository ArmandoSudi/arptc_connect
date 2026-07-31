import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetLifecyclePolicy', () {
    test('allows the defined happy-path lifecycle', () {
      const path = [
        AssetStatus.planned,
        AssetStatus.ordered,
        AssetStatus.received,
        AssetStatus.inStock,
        AssetStatus.configured,
        AssetStatus.assigned,
        AssetStatus.returned,
        AssetStatus.retired,
        AssetStatus.disposed,
      ];

      for (var index = 0; index < path.length - 1; index++) {
        expect(
          AssetLifecyclePolicy.canTransition(
            from: path[index],
            to: path[index + 1],
            assignedUserId: 'agent-1',
          ),
          isTrue,
          reason: '${path[index]} -> ${path[index + 1]}',
        );
      }
    });

    test('rejects terminal and skipped transitions', () {
      expect(
        AssetLifecyclePolicy.validate(
          from: AssetStatus.disposed,
          to: AssetStatus.assigned,
          assignedUserId: 'agent-1',
        ),
        contains(AssetTransitionIssue.transitionNotAllowed),
      );
      expect(
        AssetLifecyclePolicy.validate(
          from: AssetStatus.inStock,
          to: AssetStatus.assigned,
        ),
        contains(AssetTransitionIssue.assigneeRequired),
      );
    });

    test('assigned asset requires a custodian', () {
      expect(
        () => Asset(
          id: 'asset-1',
          assetTag: 'ARPTC-001',
          categoryId: 'laptop',
          categoryName: 'Laptop',
          type: 'Computer',
          brand: 'Dell',
          model: 'Latitude',
          status: AssetStatus.assigned,
          condition: AssetCondition.good,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });
  });
}
