import 'knowledge_serialization.dart';

class KnowledgeActor {
  factory KnowledgeActor({
    required String userId,
    required String name,
    required String email,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'A user ID is required.');
    }
    return KnowledgeActor._(
      userId: normalizedUserId,
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
  }

  const KnowledgeActor._({
    required this.userId,
    required this.name,
    required this.email,
  });

  final String userId;
  final String name;
  final String email;

  factory KnowledgeActor.fromMap(Map<String, dynamic> data) {
    return KnowledgeActor(
      userId: knowledgeString(data, 'userId'),
      name: knowledgeString(data, 'name'),
      email: knowledgeString(data, 'email'),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'email': email,
      };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeActor &&
            userId == other.userId &&
            name == other.name &&
            email == other.email;
  }

  @override
  int get hashCode => Object.hash(userId, name, email);
}
