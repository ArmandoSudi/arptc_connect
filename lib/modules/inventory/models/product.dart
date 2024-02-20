class Product {
  final String? id;
  final String name;
  final String unit;
  final int quantity;

//<editor-fold desc="Data Methods">
  const Product({
    this.id,
    required this.name,
    required this.unit,
    required this.quantity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          unit == other.unit &&
          quantity == other.quantity);

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ unit.hashCode ^ quantity.hashCode;

  @override
  String toString() {
    return 'Product{' +
        ' id: $id,' +
        ' name: $name,' +
        ' unit: $unit,' +
        ' quantity: $quantity,' +
        '}';
  }

  Product copyWith({
    String? id,
    String? name,
    String? unit,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'quantity': quantity,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    return Product(
      id: id ?? map['id'] as String,
      name: map['name'] as String,
      unit: map['unit'] as String,
      quantity: map['quantity'] as int,
    );
  }

//</editor-fold>
}