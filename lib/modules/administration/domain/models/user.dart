import 'dart:developer';

class User {
  final String? id;
  final String firstName;
  final String name;
  final String email;
  final List<String> roles;

//<editor-fold desc="Data Methods">
  const User({
    this.id,
    required this.firstName,
    required this.name,
    required this.email,
    required this.roles,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          firstName == other.firstName &&
          name == other.name &&
          email == other.email &&
          roles == other.roles);

  @override
  int get hashCode =>
      id.hashCode ^
      firstName.hashCode ^
      name.hashCode ^
      email.hashCode ^
      roles.hashCode;

  @override
  String toString() {
    return 'User{ id: $id, firstName: $firstName, name: $name, email: $email, roles: $roles,}';
  }

  User copyWith({
    String? id,
    String? firstName,
    String? name,
    String? email,
    List<String>? roles,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'name': name,
      'email': email,
      'roles': roles,
    };
  }

  factory User.fromMap(Map<String, dynamic> map, {String? id}) {

    final roleTmp = map['roles'].map((item) => item.toString()).toList();

    log("Role : ${roleTmp.runtimeType}");
    log("MAP : $map");

    return User(
      id: id ?? map['id'] as String,
      firstName: map['firstName'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      roles: roleTmp.cast<String>(),
    );
  }

//</editor-fold>
}