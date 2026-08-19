import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';

import 'firestore_model_helpers.dart';
import 'incident_enums.dart';

class IncidentUser {
  const IncidentUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.departmentId,
    required this.departmentName,
    required this.serviceId,
    required this.serviceName,
    required this.matricule,
    required this.role,
  });

  final String id;
  final String displayName;
  final String email;
  final String departmentId;
  final String departmentName;
  final String serviceId;
  final String serviceName;
  final String matricule;
  final IncidentRole role;

  factory IncidentUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final firstName = stringFromFirestore(data, 'firstName');
    final name = stringFromFirestore(data, 'name');
    final postName = stringFromFirestore(data, 'postName');
    final fullName = stringFromFirestore(data, 'fullName');
    final displayName = [
      firstName,
      name,
      postName,
    ].where((piece) => piece.isNotEmpty).join(' ');

    final rawPermissions = data['modulePermissions'];
    final permissions = Modules.normalizePermissions(
      rawPermissions is Map<String, dynamic>
          ? rawPermissions
          : rawPermissions is Map
              ? Map<String, dynamic>.from(rawPermissions)
              : null,
      includeDefaultModules: false,
    );
    final incidentRole = stringFromFirestore(data, 'incidentRole');

    return IncidentUser(
      id: stringFromFirestore(data, 'userId').isNotEmpty
          ? stringFromFirestore(data, 'userId')
          : stringFromFirestore(data, 'uid').isNotEmpty
              ? stringFromFirestore(data, 'uid')
              : snapshot.id,
      displayName: displayName.isNotEmpty ? displayName : fullName,
      email: stringFromFirestore(data, 'email'),
      departmentId: stringFromFirestore(data, 'departmentId'),
      departmentName: stringFromFirestore(data, 'departmentName'),
      serviceId: stringFromFirestore(data, 'serviceId'),
      serviceName: stringFromFirestore(data, 'serviceName'),
      matricule: stringFromFirestore(data, 'matricule'),
      role: IncidentRole.fromValue(
        permissions['support'] ??
            permissions['ticketing'] ??
            permissions['incident'] ??
            permissions['incidents'] ??
            permissions['incidentmanagement'] ??
            permissions['incident_management'] ??
            permissions['ticket'] ??
            permissions['tickets'] ??
            incidentRole,
      ),
    );
  }

  factory IncidentUser.fromDirectoryFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return IncidentUser.fromDirectoryMap({
      'id': snapshot.id,
      ...?snapshot.data(),
    });
  }

  factory IncidentUser.fromDirectoryMap(Map<String, dynamic> data) {
    final pathNames = data['organizationPathNames'] is Iterable
        ? (data['organizationPathNames'] as Iterable)
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final departmentId = stringFromFirestore(data, 'departmentId');
    final serviceId = stringFromFirestore(data, 'serviceId');
    final departmentName =
        departmentId.isNotEmpty && pathNames.isNotEmpty ? pathNames.first : '';
    final serviceName =
        serviceId.isNotEmpty && pathNames.length > 1 ? pathNames[1] : '';
    return IncidentUser(
      id: stringFromFirestore(data, 'id'),
      displayName: stringFromFirestore(data, 'displayName'),
      email: stringFromFirestore(data, 'email'),
      departmentId: departmentId,
      departmentName: departmentName,
      serviceId: serviceId,
      serviceName: serviceName,
      matricule: '',
      role: IncidentRole.fromValue(
        stringFromFirestore(data, 'incidentRole'),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName.trim(),
      'email': email.trim(),
      'departmentId': departmentId.trim(),
      'departmentName': departmentName.trim(),
      'serviceId': serviceId.trim(),
      'serviceName': serviceName.trim(),
      'matricule': matricule.trim(),
      'incidentRole': role.value,
    };
  }
}
