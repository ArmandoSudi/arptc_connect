import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:flutter_test/flutter_test.dart';

SoftwareLicence licence({
  int purchased = 10,
  int allocated = 3,
  DateTime? expiry,
}) =>
    SoftwareLicence(
      id: 'licence-1',
      softwareProduct: 'Office Suite',
      vendor: 'Vendor',
      licenceType: SoftwareLicenceType.namedUser,
      purchasedQuantity: purchased,
      allocatedQuantity: allocated,
      complianceStatus: LicenceComplianceStatus.compliant,
      purchaseDate: DateTime.utc(2026, 1, 1),
      effectiveDate: DateTime.utc(2026, 1, 1),
      expiryDate: expiry,
      updatedAt: DateTime.utc(2026, 7, 31),
    );

void main() {
  test('calculates allocations and availability', () {
    final value = licence();
    expect(value.availableQuantity, 7);
    expect(value.canAllocate(7, at: DateTime.utc(2026, 7, 31)), isTrue);
    expect(value.canAllocate(8, at: DateTime.utc(2026, 7, 31)), isFalse);
  });

  test('represents over-allocation without hiding compliance exposure', () {
    final value = licence(purchased: 2, allocated: 3);
    expect(value.availableQuantity, -1);
    expect(value.isOverAllocated, isTrue);
    expect(value.canAllocate(1), isFalse);
  });

  test('does not allocate an expired licence', () {
    final value = licence(expiry: DateTime.utc(2026, 6, 1));
    expect(value.canAllocate(1, at: DateTime.utc(2026, 7, 31)), isFalse);
  });

  test('unrestricted serialization cannot expose licence secrets', () {
    final parsed = SoftwareLicence.fromMap('licence-1', {
      ...licence().toFirestore(),
      'productKey': 'SECRET',
      'activationKey': 'SECRET-2',
      'credential': 'SECRET-3',
    });
    final serialized = parsed.toFirestore();

    expect(serialized.keys, isNot(contains('productKey')));
    expect(serialized.keys, isNot(contains('activationKey')));
    expect(serialized.keys, isNot(contains('credential')));
  });
}
