// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AgentImpl _$$AgentImplFromJson(Map<String, dynamic> json) => _$AgentImpl(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      matricule: json['matricule'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      department: json['department'] as String?,
      departmentId: json['departmentId'] as String?,
      service: json['service'] as String?,
      serviceId: json['serviceId'] as String?,
      bureau: json['bureau'] as String?,
      bureauId: json['bureauId'] as String?,
      organizationSchemaVersion:
          (json['organizationSchemaVersion'] as num?)?.toInt() ?? 2,
      organizationId: json['organizationId'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      primaryOrganizationUnitId:
          json['primaryOrganizationUnitId'] as String? ?? '',
      primaryOrganizationUnitName:
          json['primaryOrganizationUnitName'] as String? ?? '',
      primaryOrganizationUnitType:
          json['primaryOrganizationUnitType'] as String? ?? '',
      primaryAssignmentId: json['primaryAssignmentId'] as String? ?? '',
      organizationAncestorUnitIds:
          (json['organizationAncestorUnitIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const <String>[],
      organizationPathUnitIds:
          (json['organizationPathUnitIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const <String>[],
      organizationPathNames: (json['organizationPathNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      scopeKeys: (json['scopeKeys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      jobTitle: json['jobTitle'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      modulePermissions:
          (json['modulePermissions'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, e as String),
              ) ??
              const <String, String>{},
      fonction: json['fonction'] as String?,
      category: json['category'] as String? ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      dependants: (json['dependants'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$$AgentImplToJson(_$AgentImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'genre': instance.genre,
      'matricule': instance.matricule,
      'dob': instance.dob,
      'department': instance.department,
      'departmentId': instance.departmentId,
      'service': instance.service,
      'serviceId': instance.serviceId,
      'bureau': instance.bureau,
      'bureauId': instance.bureauId,
      'organizationSchemaVersion': instance.organizationSchemaVersion,
      'organizationId': instance.organizationId,
      'organizationName': instance.organizationName,
      'primaryOrganizationUnitId': instance.primaryOrganizationUnitId,
      'primaryOrganizationUnitName': instance.primaryOrganizationUnitName,
      'primaryOrganizationUnitType': instance.primaryOrganizationUnitType,
      'primaryAssignmentId': instance.primaryAssignmentId,
      'organizationAncestorUnitIds': instance.organizationAncestorUnitIds,
      'organizationPathUnitIds': instance.organizationPathUnitIds,
      'organizationPathNames': instance.organizationPathNames,
      'scopeKeys': instance.scopeKeys,
      'jobTitle': instance.jobTitle,
      'isActive': instance.isActive,
      'modulePermissions': instance.modulePermissions,
      'fonction': instance.fonction,
      'category': instance.category,
      'roles': instance.roles,
      'dependants': instance.dependants,
    };
