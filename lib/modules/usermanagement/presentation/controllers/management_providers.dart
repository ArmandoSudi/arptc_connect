import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_bureau.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_department.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final umDepartmentsProvider =
    FutureProvider<List<UserManagementDepartment>>((ref) async {
  return ref.read(userManagementRepositoryProvider).fetchDepartments();
});

final umServicesProvider =
    FutureProvider<List<UserManagementService>>((ref) async {
  return ref.read(userManagementRepositoryProvider).fetchServices();
});

final umBureauxProvider =
    FutureProvider<List<UserManagementBureau>>((ref) async {
  return ref.read(userManagementRepositoryProvider).fetchBureaux();
});

final umAgentsProvider = FutureProvider<List<UserManagementAgent>>((ref) async {
  return ref.read(userManagementRepositoryProvider).fetchAgents();
});

final umModulesProvider = StreamProvider<List<UserManagementModule>>((ref) {
  return ref.read(userManagementRepositoryProvider).watchModules();
});

final umBureauSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final umAgentSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final filteredUmBureauxProvider =
    Provider<AsyncValue<List<UserManagementBureau>>>((ref) {
  final bureauxAsync = ref.watch(umBureauxProvider);
  final query = ref.watch(umBureauSearchQueryProvider).trim().toLowerCase();

  return bureauxAsync.whenData((bureaux) {
    if (query.isEmpty) {
      return bureaux;
    }

    return bureaux.where((bureau) {
      return bureau.nameLower.contains(query) ||
          bureau.code.toLowerCase().contains(query) ||
          bureau.id.toLowerCase().contains(query);
    }).toList();
  });
});

final filteredUmAgentsProvider =
    Provider<AsyncValue<List<UserManagementAgent>>>((ref) {
  final agentsAsync = ref.watch(umAgentsProvider);
  final query = ref.watch(umAgentSearchQueryProvider).trim().toLowerCase();

  return agentsAsync.whenData((agents) {
    if (query.isEmpty) {
      return agents;
    }

    return agents.where((agent) {
      return agent.displayNameLower.contains(query) ||
          agent.postName.toLowerCase().contains(query) ||
          agent.matricule.toLowerCase().contains(query) ||
          agent.emailLower.contains(query) ||
          agent.position.toLowerCase().contains(query);
    }).toList();
  });
});

final servicesByDepartmentProvider =
    Provider.family<AsyncValue<List<UserManagementService>>, String>(
        (ref, departmentId) {
  final servicesAsync = ref.watch(umServicesProvider);

  return servicesAsync.whenData((services) {
    if (departmentId.isEmpty) {
      return services;
    }
    return services
        .where((service) => service.departmentId == departmentId)
        .toList();
  });
});

final bureauxByServiceProvider =
    Provider.family<AsyncValue<List<UserManagementBureau>>, String>(
        (ref, serviceId) {
  final bureauxAsync = ref.watch(umBureauxProvider);

  return bureauxAsync.whenData((bureaux) {
    if (serviceId.isEmpty) {
      return bureaux;
    }
    return bureaux.where((bureau) => bureau.serviceId == serviceId).toList();
  });
});
