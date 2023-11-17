// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courrier_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CourrierImpl _$$CourrierImplFromJson(Map<String, dynamic> json) =>
    _$CourrierImpl(
      sender: json['sender'] as String,
      object: json['object'] as String,
      annotations: (json['annotations'] as List<dynamic>)
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      url: json['url'] as String?,
      date: const TimestampSerializer().fromJson(json['date'] as Timestamp),
      receptionDate: const TimestampSerializer()
          .fromJson(json['reception_date'] as Timestamp),
    );

Map<String, dynamic> _$$CourrierImplToJson(_$CourrierImpl instance) =>
    <String, dynamic>{
      'sender': instance.sender,
      'object': instance.object,
      'annotations': instance.annotations,
      'url': instance.url,
      'date': const TimestampSerializer().toJson(instance.date),
      'reception_date':
          const TimestampSerializer().toJson(instance.receptionDate),
    };
