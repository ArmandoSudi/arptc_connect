import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_bureau.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_department.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final umDepartmentDetailsProvider =
    FutureProvider.family<UserManagementDepartment, String>(
        (ref, departmentId) async {
  return ref
      .read(userManagementRepositoryProvider)
      .fetchDepartmentById(departmentId);
});

final umServiceDetailsProvider =
    FutureProvider.family<UserManagementService, String>(
        (ref, serviceId) async {
  return ref.read(userManagementRepositoryProvider).fetchServiceById(serviceId);
});

final umBureauDetailsProvider =
    FutureProvider.family<UserManagementBureau, String>((ref, bureauId) async {
  return ref.read(userManagementRepositoryProvider).fetchBureauById(bureauId);
});

final umAgentDetailsProvider =
    FutureProvider.family<UserManagementAgent, String>((ref, agentId) async {
  return ref.read(userManagementRepositoryProvider).fetchAgentById(agentId);
});

final umModuleDetailsProvider =
    FutureProvider.family<UserManagementModule, String>((ref, moduleId) async {
  return ref.read(userManagementRepositoryProvider).fetchModuleById(moduleId);
});
