import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final userManagementUsersProvider =
    FutureProvider<List<UserManagementUser>>((ref) async {
  return ref.read(userManagementRepositoryProvider).fetchUsers();
});

final filteredUserManagementUsersProvider =
    Provider<AsyncValue<List<UserManagementUser>>>((ref) {
  final usersAsync = ref.watch(userManagementUsersProvider);
  final query = ref.watch(userSearchQueryProvider).trim().toLowerCase();

  return usersAsync.whenData((users) {
    if (query.isEmpty) {
      return users;
    }

    return users.where((user) {
      final firstName = user.firstName.toLowerCase();
      final name = user.name.toLowerCase();
      final postName = user.postName.toLowerCase();
      final matricule = user.matricule.toLowerCase();
      final displayName = user.displayNameLower;
      return firstName.contains(query) ||
          name.contains(query) ||
          postName.contains(query) ||
          matricule.contains(query) ||
          displayName.contains(query);
    }).toList();
  });
});
