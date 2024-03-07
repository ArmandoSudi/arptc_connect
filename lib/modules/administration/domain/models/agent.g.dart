// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AgentImpl _$$AgentImplFromJson(Map<String, dynamic> json) => _$AgentImpl(
      name: json['name'] as String,
      email: json['email'] as String,
      genre: json['genre'] as String,
      matricule: json['matricule'] as String,
      dob: json['dob'] as String,
      direction: json['direction'] as String?,
      service: json['service'] as String?,
      bureau: json['bureau'] as String?,
      fonction: json['fonction'] as String?,
      category: json['category'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$AgentImplToJson(_$AgentImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'genre': instance.genre,
      'matricule': instance.matricule,
      'dob': instance.dob,
      'direction': instance.direction,
      'service': instance.service,
      'bureau': instance.bureau,
      'fonction': instance.fonction,
      'category': instance.category,
      'roles': instance.roles,
    };
