import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/tempstamp_serializer.dart';

part 'courrier_model.freezed.dart';
part 'courrier_model.g.dart';

@Freezed()
class Courrier with _$Courrier {
  const factory Courrier({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    required String sender,
    required String object,
    required List<Map<String, String>> annotations,
    String? url,
    @TimestampSerializer() required DateTime date,
    @TimestampSerializer() @JsonKey(name: "reception_date")required DateTime receptionDate,
}) = _Courrier;

  factory Courrier.fromJson(Map<String, dynamic> json) => _$CourrierFromJson(json);

  factory Courrier.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) throw Exception("Document data was null");

    return Courrier.fromJson(doc.data() as Map<String, Object?>).copyWith(id: doc.id);
  }
}