import 'dart:developer';

import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class TaskRepository {

  final String path = "tasks";
  final FirestoreClient firestoreClient;

  TaskRepository(this.firestoreClient);

  Future<List<Task>> getTasks() async {
    try {
      final results = await firestoreClient.fetchAll(collection: path);
      return results
          .map(
            (item) => Task.fromMap(item.data, id: item.id),
      )
          .toList();
    } catch (err, stckTrace) {
      log("Error fetching tasks: $err");
      log("StackTrace: $stckTrace");
      throw (Exception(err));
    }
  }

  Future<Task> getTaskById(String id) async {
    try{
      final result = await firestoreClient.fetchById(collection: path, id: id);
      return Task.fromMap(result.data, id: result.id);
    } catch (err) {
      throw (Exception(err));
    }
  }

  Future<void >addTask(Task task) async {
    try {
      await firestoreClient.add(
        collection: path,
        data: task.toMap(),
      );
    } catch (err) {
      throw (Exception(err));
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await firestoreClient.delete(
        collection: path,
        id: id,
      );
    } catch (err) {
      throw (Exception(err));
    }
  }

  // Just an experiment to see if we can use update with the repository
  Query<Task> tasksQuery() {
    return firestoreClient.firestore
        .collection(path)
        .withConverter<Task>(
      fromFirestore: (snapshot, _) => Task.fromMap(snapshot.data()!, id: snapshot.id),
      toFirestore: (task, _) => task.toMap(),
    );
  }

}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.read(firestoreClientProvider),);
});

// Provider to retunr a single task
final taskProvider = FutureProvider.family<Task, String>((ref, id) async {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return await taskRepository.getTaskById(id);
});