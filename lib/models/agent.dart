import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent.freezed.dart';
part 'agent.g.dart';

@Freezed()
class Agent with _$Agent{

  const Agent._();

  const factory Agent({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    required String name,
    required String email,
    required String genre,
    required String matricule,
    required String dob,
    String? direction,
    String? service,
    String? bureau,
    String? fonction,
    required String category,
    required List<String> roles,
  }) = _Agent;

  factory Agent.newEmpty({required String userId}) => Agent(
      id: null,
      name: '',
      email: '',
      genre: '',
      matricule: '',
      dob: '',
      category: '',
      roles: [] );

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);

  factory Agent.fromDocument(DocumentSnapshot doc) {
    if (doc.data() == null) throw Exception("Agent document was null");

    return Agent.fromJson(doc.data() as Map<String, Object?>).copyWith(id: doc.id);
  }

}