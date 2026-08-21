class InventoryQuantity implements Comparable<InventoryQuantity> {
  const InventoryQuantity.fromMilliUnits(this.milliUnits);

  static const int scale = 1000;
  static const InventoryQuantity zero = InventoryQuantity.fromMilliUnits(0);

  final int milliUnits;

  factory InventoryQuantity.parse(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,3}))?$').firstMatch(normalized);
    if (match == null) {
      throw const FormatException(
        'Enter a quantity with no more than three decimal places.',
      );
    }
    final whole = int.parse(match.group(2)!);
    final fraction = (match.group(3) ?? '').padRight(3, '0');
    final absolute =
        whole * scale + int.parse(fraction.isEmpty ? '0' : fraction);
    return InventoryQuantity.fromMilliUnits(
      match.group(1) == '-' ? -absolute : absolute,
    );
  }

  factory InventoryQuantity.fromFirestore(Object? value) {
    if (value is int) return InventoryQuantity.fromMilliUnits(value);
    if (value is num) return InventoryQuantity.fromMilliUnits(value.toInt());
    return InventoryQuantity.fromMilliUnits(
      int.tryParse(value?.toString() ?? '') ?? 0,
    );
  }

  bool get isZero => milliUnits == 0;
  bool get isPositive => milliUnits > 0;
  bool get isNegative => milliUnits < 0;

  InventoryQuantity operator +(InventoryQuantity other) =>
      InventoryQuantity.fromMilliUnits(milliUnits + other.milliUnits);

  InventoryQuantity operator -(InventoryQuantity other) =>
      InventoryQuantity.fromMilliUnits(milliUnits - other.milliUnits);

  InventoryQuantity clampToZero() => isNegative ? zero : this;

  bool operator <(InventoryQuantity other) => milliUnits < other.milliUnits;
  bool operator <=(InventoryQuantity other) => milliUnits <= other.milliUnits;
  bool operator >(InventoryQuantity other) => milliUnits > other.milliUnits;
  bool operator >=(InventoryQuantity other) => milliUnits >= other.milliUnits;

  String format({bool trimTrailingZeros = true}) {
    final negative = milliUnits < 0;
    final absolute = milliUnits.abs();
    final whole = absolute ~/ scale;
    var fraction = (absolute % scale).toString().padLeft(3, '0');
    if (trimTrailingZeros) {
      fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    }
    final value = fraction.isEmpty ? '$whole' : '$whole.$fraction';
    return negative ? '-$value' : value;
  }

  @override
  int compareTo(InventoryQuantity other) =>
      milliUnits.compareTo(other.milliUnits);

  @override
  bool operator ==(Object other) =>
      other is InventoryQuantity && other.milliUnits == milliUnits;

  @override
  int get hashCode => milliUnits.hashCode;

  @override
  String toString() => format();
}
