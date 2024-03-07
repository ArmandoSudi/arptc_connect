import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'direction.freezed.dart';
part 'direction.g.dart';

@Freezed()
class Direction with _$Direction {
  const Direction._();

  const factory Direction({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    required String name,
    @JsonKey(name: "short_name") required String shortName,
  }) = _Direction;

  factory Direction.newEmpty({required String userId}) => Direction(
      id: null,
      name: '',
      shortName: '',
      );

  factory Direction.fromJson(Map<String, dynamic> json) =>
      _$DirectionFromJson(json);

  factory Direction.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) throw Exception("Direction document was null");

    return Direction.fromJson(doc.data() as Map<String, Object?>).copyWith(id: doc.id);
  }
}