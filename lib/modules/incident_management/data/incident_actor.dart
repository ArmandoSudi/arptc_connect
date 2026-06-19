import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';

class IncidentActor {
  const IncidentActor({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final String userId;
  final String name;
  final String email;
  final IncidentRole role;

  bool get isEmpty => userId.trim().isEmpty;
}
