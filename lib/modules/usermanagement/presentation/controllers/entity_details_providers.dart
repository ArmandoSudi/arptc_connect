import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final umAgentDetailsProvider =
    StreamProvider.family<UserManagementAgent, String>((ref, agentId) {
  return ref.read(userManagementRepositoryProvider).watchAgentById(agentId);
});

final umModuleDetailsProvider =
    FutureProvider.family<UserManagementModule, String>((ref, moduleId) async {
  return ref.read(userManagementRepositoryProvider).fetchModuleById(moduleId);
});
