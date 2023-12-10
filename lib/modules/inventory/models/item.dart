import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@Freezed()
class Item with _$Item{

  const Item._();

  const factory Item({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    required String name,
    required String model,
    required String category,
    required String unit,
    required int quantity,
  }) = _Item;

  factory Item.newEmpty({required String userId}) => Item(
      id: null,
      name: '',
      model: '',
      category: '',
      quantity: 0,
      unit: '',
      );

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  factory Item.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) throw Exception("Item document was null");

    return Item.fromJson(doc.data() as Map<String, Object?>).copyWith(id: doc.id);
  }

}