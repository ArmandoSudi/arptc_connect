import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

class AssetAssignee {
  const AssetAssignee({
    required this.id,
    required this.displayName,
    required this.email,
    this.departmentId = '',
  });

  final String id;
  final String displayName;
  final String email;
  final String departmentId;

  factory AssetAssignee.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      AssetAssignee.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory AssetAssignee.fromMap(String id, Map<String, Object?> data) {
    final parts = [
      itsmAssetString(data, 'firstName'),
      itsmAssetString(data, 'name'),
      itsmAssetString(data, 'postName'),
    ].where((part) => part.isNotEmpty);
    final email = itsmAssetString(data, 'email');
    return AssetAssignee(
      id: id.trim(),
      displayName:
          parts.join(' ').trim().isNotEmpty ? parts.join(' ').trim() : email,
      email: email,
      departmentId: itsmAssetString(data, 'departmentId'),
    );
  }
}
