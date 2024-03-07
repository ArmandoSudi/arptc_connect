import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bureau.freezed.dart';
part 'bureau.g.dart';
@freezed
class Bureau with _$Bureau {
  const Bureau._();

  const factory Bureau({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    required String name,
    @JsonKey(name: "direction_ref") required String directionRef,
  }) = _Bureau;

  factory Bureau.newEmpty({required String userId}) => Bureau(
    id: null,
    name: '',
    directionRef: '',
  );

  factory Bureau.fromJson(Map<String, dynamic> json) =>
      _$BureauFromJson(json);

  factory Bureau.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) throw Exception("Service document was null");

    return Bureau.fromJson(doc.data() as Map<String, Object?>).copyWith(id: doc.id);
  }
}