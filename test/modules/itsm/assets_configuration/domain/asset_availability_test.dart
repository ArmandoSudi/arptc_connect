import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AssetSummary summary({
    required AssetLifecycleStatus status,
    bool isInStock = false,
    String assignedUserName = '',
  }) =>
      AssetSummary(
        id: 'asset-1',
        assetTag: 'ARPTC-001',
        name: 'Laptop',
        categoryName: 'Computer',
        status: status,
        isInStock: isInStock,
        assignedUserName: assignedUserName,
      );

  test('availability distinguishes stock, custody, and decommissioning', () {
    expect(
      summary(status: AssetLifecycleStatus.inStock, isInStock: true)
          .availability,
      AssetAvailability.inStock,
    );
    expect(
      summary(
        status: AssetLifecycleStatus.assigned,
        assignedUserName: 'Agent One',
      ).availability,
      AssetAvailability.assigned,
    );
    expect(
      summary(
        status: AssetLifecycleStatus.retired,
        assignedUserName: 'Stale legacy value',
      ).availability,
      AssetAvailability.decommissioned,
    );
    for (final status in [
      AssetLifecycleStatus.lost,
      AssetLifecycleStatus.stolen,
    ]) {
      expect(
        summary(
          status: status,
          assignedUserName: 'Current custodian',
        ).availability,
        AssetAvailability.unavailable,
      );
    }
  });
}
