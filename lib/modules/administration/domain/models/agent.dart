// Freezed applies JsonKey metadata to generated fields.
// ignore_for_file: invalid_annotation_target

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent.freezed.dart';
part 'agent.g.dart';

@Freezed()
class Agent with _$Agent {
  const Agent._();

  const factory Agent(
      {@JsonKey(includeFromJson: false, includeToJson: false) String? id,
      @Default('') String name,
      @Default('') String email,
      @Default('') String genre,
      @Default('') String matricule,
      @Default('') String dob,
      String? department,
      String? departmentId,
      String? service,
      String? serviceId,
      String? bureau,
      String? bureauId,
      @Default(2) int organizationSchemaVersion,
      @Default('') String organizationId,
      @Default('') String organizationName,
      @Default('') String primaryOrganizationUnitId,
      @Default('') String primaryOrganizationUnitName,
      @Default('') String primaryOrganizationUnitType,
      @Default('') String primaryAssignmentId,
      @Default(<String>[]) List<String> organizationAncestorUnitIds,
      @Default(<String>[]) List<String> organizationPathUnitIds,
      @Default(<String>[]) List<String> organizationPathNames,
      @Default(<String>[]) List<String> scopeKeys,
      @Default('') String jobTitle,
      @Default(true) bool isActive,
      @Default(<String, String>{}) Map<String, String> modulePermissions,
      String? fonction,
      @Default('') String category,
      @Default(<String>[]) List<String> roles,
      List<Map<String, dynamic>>? dependants}) = _Agent;

  factory Agent.newEmpty({required String userId}) => const Agent(
      id: null,
      name: '',
      email: '',
      genre: '',
      matricule: '',
      dob: '',
      category: '',
      roles: []);

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);

  factory Agent.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) throw Exception("Agent document was null");

    return Agent.fromJson(doc.data() as Map<String, Object?>)
        .copyWith(id: doc.id);
  }
}
