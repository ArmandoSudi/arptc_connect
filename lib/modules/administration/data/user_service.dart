import 'dart:developer';

import 'package:arptc_connect/modules/administration/domain/models/user.dart';
import 'package:arptc_connect/utils/firestore_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserService {
  final FirestoreClient firestoreClient;

  UserService(this.firestoreClient);

  Future<List<User>> fetchAllUsers() async {
    try {
      final results = await firestoreClient.fetchAll(collection: "users");
      return results.map((item) => User.fromMap(item.data, id: item.id)).toList();
    } catch (err) {
      log("fetchAllUsers => Error : ${err}");
      throw (Exception(err));
    }
  }

  Future<void> addUser(User user) async {
    try {
      await firestoreClient.add(
        collection: "users",
        data: user.toMap(),
      );
    } catch (err) {
      log("addUser => Error : $err");
      throw (Exception(err));
    }
  }

}

final userServiceProvider = Provider<UserService>((ref){
  return UserService(ref.read(firestoreClientProvider));
});