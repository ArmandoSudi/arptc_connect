// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemImpl _$$ItemImplFromJson(Map<String, dynamic> json) => _$ItemImpl(
      name: json['name'] as String,
      model: json['model'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as int,
    );

Map<String, dynamic> _$$ItemImplToJson(_$ItemImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'model': instance.model,
      'category': instance.category,
      'unit': instance.unit,
      'quantity': instance.quantity,
    };
