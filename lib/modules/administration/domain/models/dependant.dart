
class Dependant {
  final String name;
  final String relationship;
  final String imageURL;
  final String? id;

//<editor-fold desc="Data Methods">
  const Dependant({
    required this.name,
    required this.relationship,
    required this.imageURL,
    this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dependant &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          relationship == other.relationship &&
          imageURL == other.imageURL &&
          id == other.id);

  @override
  int get hashCode =>
      name.hashCode ^ relationship.hashCode ^ imageURL.hashCode ^ id.hashCode;

  @override
  String toString() {
    return 'Dependant{ name: $name, relationship: $relationship, imageURL: $imageURL, id: $id,}';
  }

  Dependant copyWith({
    String? name,
    String? relationship,
    String? imageURL,
    String? id,
  }) {
    return Dependant(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      imageURL: imageURL ?? this.imageURL,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'imageURL': imageURL,
      'id': id,
    };
  }

  factory Dependant.fromMap(Map<String, dynamic> map, {String? id}) {
    return Dependant(
      name: map['name'] as String,
      relationship: map['relationship'] as String,
      imageURL: map['imageURL'] as String,
      id: id ?? map['id'] as String,
    );
  }

//</editor-fold>
}