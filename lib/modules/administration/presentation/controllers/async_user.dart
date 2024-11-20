import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/user_service.dart';
import '../../domain/models/user.dart';



part 'async_user.g.dart';
@riverpod
class AsyncUser extends _$AsyncUser{

  List<User> users = [];

  @override
  FutureOr<List<User>> build() async {
    users = await fetchUsers();
    return users;
  }

  Future<List<User>> fetchUsers(){
    return ref.read(userServiceProvider).fetchAllUsers();
  }

  Future<void> addUser(User user) async {
    state = const AsyncValue.loading();
    ref.read(userServiceProvider).addUser(user);
    state = AsyncValue.data(await fetchUsers());
  }

}