import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

enum AssetParameterType {
  category,
  location,
  state;

  static AssetParameterType fromValue(Object? value) => values.firstWhere(
        (type) => type.name == value?.toString().trim().toLowerCase(),
        orElse: () => AssetParameterType.category,
      );
}

class AssetParameter {
  const AssetParameter({
    required this.id,
    required this.type,
    required this.name,
    required this.isActive,
    this.sortOrder = 0,
    this.revision = 0,
  });

  final String id;
  final AssetParameterType type;
  final String name;
  final bool isActive;
  final int sortOrder;
  final int revision;

  factory AssetParameter.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      AssetParameter.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory AssetParameter.fromMap(String id, Map<String, Object?> data) =>
      AssetParameter(
        id: id.trim(),
        type: AssetParameterType.fromValue(data['type']),
        name: itsmAssetString(data, 'name'),
        isActive: data['isActive'] != false,
        sortOrder: itsmAssetInt(data, 'sortOrder'),
        revision: itsmAssetInt(data, 'revision'),
      );
}
