import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'service.freezed.dart';
part 'service.g.dart';

// a service class with feezed that has a name, a direction reference and an id
@freezed
class Service with _$Service {
  const Service._();

  const factory Service({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    required String name,
    @JsonKey(name: "direction_ref") required String directionRef,
  }) = _Service;

  factory Service.newEmpty({required String userId}) => Service(
      id: null,
      name: '',
      directionRef: '',
      );

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  factory Service.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) throw Exception("Service document was null");

    return Service.fromJson(doc.data() as Map<String, Object?>).copyWith(id: doc.id);
  }
}