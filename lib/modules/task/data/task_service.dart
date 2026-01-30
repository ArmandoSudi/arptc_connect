// import 'package:arptc_connect/modules/task/domain/task.dart';
// import 'package:arptc_connect/utils/firestore_client.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// class TaskService {
//   final String path = "activites";
//   final FirestoreClient firestoreClient;
//
//   TaskService(this.firestoreClient);
//
//   Future<void> create(Task2 task) async {
//     try {
//       await firestoreClient.add(
//         collection: path,
//         data: task.toMap(),
//       );
//     } catch (err) {
//       throw (Exception(err));
//     }
//   }
//
//   // Future<void> update(Task2 task) async {
//   //   await repository.updateTask(task);
//   // }
//
//   // Future<void> delete(String id) async {
//   //   await repository.deleteTask(id);
//   // }
//
//   Future<List<Task2>> fetchByDepartment(String department) async {
//     try{
//       final results = await firestoreClient.fetchAllBy(collection: path, field: "department", value: department);
//       return results
//           .map(
//             (item) => Task2.fromMap(item.data, id: item.id),
//       )
//           .toList();
//     } catch (err) {
//       throw (Exception(err));
//     }
//   }
//
//   Future<List<Task2>> fetchAll() async {
//     try {
//       final results = await firestoreClient.fetchAll(collection: path);
//       return results
//           .map(
//             (item) => Task2.fromMap(item.data, id: item.id),
//       )
//           .toList();
//     } catch (err) {
//       throw (Exception(err));
//     }
//   }
// }
//
// final taskServiceProvider = Provider<TaskService>((ref) {
//   return TaskService(ref.read(firestoreClientProvider));
// });