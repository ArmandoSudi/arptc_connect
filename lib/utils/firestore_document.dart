class FirestoreDocument {
  final String id;
  final Map<String, dynamic> data;

  FirestoreDocument({
    required this.id,
    this.data = const {}
  });
}