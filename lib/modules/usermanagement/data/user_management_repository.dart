import 'dart:developer';

import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_bureau.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_department.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_service.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_user.dart';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserManagementRepository {
  UserManagementRepository(this.firestoreClient);

  final FirestoreClient firestoreClient;
  static const String _usersPath = 'users';
  static const String _departmentsPath = 'departments';
  static const String _servicesPath = 'services';
  static const String _bureauxPath = 'bureaux';
  static const String _agentsPath = 'agents';
  static const String _modulesPath = 'modules';

  Future<List<UserManagementUser>> fetchUsers() async {
    try {
      final documents = await firestoreClient.fetchAll(collection: _usersPath);
      final users = documents
          .map((document) =>
              UserManagementUser.fromMap(document.data, id: document.id))
          .toList();

      users.sort(
        (left, right) =>
            left.displayNameLower.compareTo(right.displayNameLower),
      );

      return users;
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchUsers error => $error');
      log('UserManagementRepository::fetchUsers stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<UserManagementUser> fetchUserById(String id) async {
    try {
      final document =
          await firestoreClient.fetchById(collection: _usersPath, id: id);
      return UserManagementUser.fromMap(document.data, id: document.id);
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchUserById error => $error');
      log('UserManagementRepository::fetchUserById stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<List<UserManagementDepartment>> fetchDepartments() async {
    try {
      final documents =
          await firestoreClient.fetchAll(collection: _departmentsPath);
      final departments = documents
          .map((document) =>
              UserManagementDepartment.fromMap(document.data, id: document.id))
          .toList();

      departments.sort(
        (left, right) => left.nameLower.compareTo(right.nameLower),
      );

      return departments;
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchDepartments error => $error');
      log('UserManagementRepository::fetchDepartments stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> addDepartment(UserManagementDepartment department) async {
    try {
      await firestoreClient.add(
        collection: _departmentsPath,
        data: department.toMap(),
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::addDepartment error => $error');
      log('UserManagementRepository::addDepartment stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<UserManagementDepartment> fetchDepartmentById(String id) async {
    try {
      final document =
          await firestoreClient.fetchById(collection: _departmentsPath, id: id);
      return UserManagementDepartment.fromMap(document.data, id: document.id);
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchDepartmentById error => $error');
      log('UserManagementRepository::fetchDepartmentById stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> updateDepartment(UserManagementDepartment department) async {
    try {
      await firestoreClient.firestore
          .collection(_departmentsPath)
          .doc(department.id)
          .update({
        ...department.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      log('UserManagementRepository::updateDepartment error => $error');
      log('UserManagementRepository::updateDepartment stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> deleteDepartment(String departmentId) async {
    try {
      await firestoreClient.delete(
        collection: _departmentsPath,
        id: departmentId,
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::deleteDepartment error => $error');
      log('UserManagementRepository::deleteDepartment stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<List<UserManagementService>> fetchServices() async {
    try {
      final documents =
          await firestoreClient.fetchAll(collection: _servicesPath);
      final services = documents
          .map((document) =>
              UserManagementService.fromMap(document.data, id: document.id))
          .toList();

      services.sort(
        (left, right) => left.nameLower.compareTo(right.nameLower),
      );

      return services;
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchServices error => $error');
      log('UserManagementRepository::fetchServices stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> addService(UserManagementService service) async {
    try {
      await firestoreClient.add(
        collection: _servicesPath,
        data: service.toMap(),
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::addService error => $error');
      log('UserManagementRepository::addService stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<UserManagementService> fetchServiceById(String id) async {
    try {
      final document =
          await firestoreClient.fetchById(collection: _servicesPath, id: id);
      return UserManagementService.fromMap(document.data, id: document.id);
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchServiceById error => $error');
      log('UserManagementRepository::fetchServiceById stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> updateService(UserManagementService service) async {
    try {
      await firestoreClient.firestore
          .collection(_servicesPath)
          .doc(service.id)
          .update({
        ...service.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      log('UserManagementRepository::updateService error => $error');
      log('UserManagementRepository::updateService stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await firestoreClient.delete(
        collection: _servicesPath,
        id: serviceId,
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::deleteService error => $error');
      log('UserManagementRepository::deleteService stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<List<UserManagementBureau>> fetchBureaux() async {
    try {
      final documents =
          await firestoreClient.fetchAll(collection: _bureauxPath);
      final bureaux = documents
          .map((document) =>
              UserManagementBureau.fromMap(document.data, id: document.id))
          .toList();

      bureaux.sort(
        (left, right) => left.nameLower.compareTo(right.nameLower),
      );

      return bureaux;
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchBureaux error => $error');
      log('UserManagementRepository::fetchBureaux stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> addBureau(UserManagementBureau bureau) async {
    try {
      await firestoreClient.add(
        collection: _bureauxPath,
        data: bureau.toMap(),
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::addBureau error => $error');
      log('UserManagementRepository::addBureau stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<UserManagementBureau> fetchBureauById(String id) async {
    try {
      final document =
          await firestoreClient.fetchById(collection: _bureauxPath, id: id);
      return UserManagementBureau.fromMap(document.data, id: document.id);
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchBureauById error => $error');
      log('UserManagementRepository::fetchBureauById stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> updateBureau(UserManagementBureau bureau) async {
    try {
      await firestoreClient.firestore
          .collection(_bureauxPath)
          .doc(bureau.id)
          .update({
        ...bureau.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      log('UserManagementRepository::updateBureau error => $error');
      log('UserManagementRepository::updateBureau stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> deleteBureau(String bureauId) async {
    try {
      await firestoreClient.delete(
        collection: _bureauxPath,
        id: bureauId,
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::deleteBureau error => $error');
      log('UserManagementRepository::deleteBureau stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<List<UserManagementAgent>> fetchAgents() async {
    try {
      final documents = await firestoreClient.fetchAll(collection: _agentsPath);
      final agents = documents
          .map((document) =>
              UserManagementAgent.fromMap(document.data, id: document.id))
          .toList();

      agents.sort(
        (left, right) =>
            left.displayNameLower.compareTo(right.displayNameLower),
      );

      return agents;
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchAgents error => $error');
      log('UserManagementRepository::fetchAgents stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> addAgent(UserManagementAgent agent) async {
    try {
      await firestoreClient.add(
        collection: _agentsPath,
        data: agent.toMap(),
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::addAgent error => $error');
      log('UserManagementRepository::addAgent stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<UserManagementAgent> fetchAgentById(String id) async {
    try {
      final document =
          await firestoreClient.fetchById(collection: _agentsPath, id: id);
      return UserManagementAgent.fromMap(document.data, id: document.id);
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchAgentById error => $error');
      log('UserManagementRepository::fetchAgentById stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> updateAgent(UserManagementAgent agent) async {
    try {
      await firestoreClient.firestore
          .collection(_agentsPath)
          .doc(agent.id)
          .update({
        ...agent.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      log('UserManagementRepository::updateAgent error => $error');
      log('UserManagementRepository::updateAgent stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> deleteAgent(String agentId) async {
    try {
      await firestoreClient.delete(
        collection: _agentsPath,
        id: agentId,
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::deleteAgent error => $error');
      log('UserManagementRepository::deleteAgent stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<List<UserManagementModule>> fetchModules() async {
    try {
      final documents =
          await firestoreClient.fetchAll(collection: _modulesPath);
      final modules = documents
          .map((document) =>
              UserManagementModule.fromMap(document.data, id: document.id))
          .toList();

      modules.sort(
        (left, right) => left.nameLower.compareTo(right.nameLower),
      );

      return modules;
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchModules error => $error');
      log('UserManagementRepository::fetchModules stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> addModule(UserManagementModule module) async {
    try {
      await firestoreClient.add(
        collection: _modulesPath,
        data: module.toMap(),
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::addModule error => $error');
      log('UserManagementRepository::addModule stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<UserManagementModule> fetchModuleById(String id) async {
    try {
      final document =
          await firestoreClient.fetchById(collection: _modulesPath, id: id);
      return UserManagementModule.fromMap(document.data, id: document.id);
    } catch (error, stackTrace) {
      log('UserManagementRepository::fetchModuleById error => $error');
      log('UserManagementRepository::fetchModuleById stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> updateModule(UserManagementModule module) async {
    try {
      await firestoreClient.firestore
          .collection(_modulesPath)
          .doc(module.id)
          .update({
        ...module.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      log('UserManagementRepository::updateModule error => $error');
      log('UserManagementRepository::updateModule stackTrace => $stackTrace');
      throw Exception(error);
    }
  }

  Future<void> deleteModule(String moduleId) async {
    try {
      await firestoreClient.delete(
        collection: _modulesPath,
        id: moduleId,
      );
    } catch (error, stackTrace) {
      log('UserManagementRepository::deleteModule error => $error');
      log('UserManagementRepository::deleteModule stackTrace => $stackTrace');
      throw Exception(error);
    }
  }
}

final userManagementRepositoryProvider =
    Provider<UserManagementRepository>((ref) {
  return UserManagementRepository(ref.read(firestoreClientProvider));
});
