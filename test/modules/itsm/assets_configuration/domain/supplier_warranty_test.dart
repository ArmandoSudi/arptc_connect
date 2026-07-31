import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final warranty = Warranty(
    id: 'warranty-1',
    reference: 'WAR-2026-01',
    supplierId: 'supplier-1',
    status: WarrantyStatus.active,
    startsAt: DateTime.utc(2026, 1, 1),
    expiresAt: DateTime.utc(2027, 1, 1),
    linkedAssetIds: const ['asset-1'],
    coveredAssetCategoryIds: const ['laptop'],
  );

  test('warranty uses an exclusive expiry boundary', () {
    expect(warranty.isActiveAt(DateTime.utc(2026, 12, 31)), isTrue);
    expect(warranty.isActiveAt(DateTime.utc(2027, 1, 1)), isFalse);
  });

  test('warranty can cover a linked asset or an asset category', () {
    expect(
      warranty.coversAsset(assetId: 'asset-1', categoryId: 'printer'),
      isTrue,
    );
    expect(
      warranty.coversAsset(assetId: 'asset-2', categoryId: 'laptop'),
      isTrue,
    );
    expect(
      warranty.coversAsset(assetId: 'asset-2', categoryId: 'printer'),
      isFalse,
    );
  });

  test('invalid ranges and incomplete resolved claims are rejected', () {
    expect(
      () => Warranty(
        id: 'bad',
        reference: 'BAD',
        supplierId: 'supplier-1',
        status: WarrantyStatus.active,
        startsAt: DateTime.utc(2027),
        expiresAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => WarrantyClaim(
        id: 'claim-1',
        warrantyId: warranty.id,
        assetId: 'asset-1',
        status: WarrantyClaimStatus.resolved,
        issueSummary: 'Battery failure',
        submittedByUserId: 'manager-1',
        submittedAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 2),
      ),
      throwsArgumentError,
    );
  });
}
