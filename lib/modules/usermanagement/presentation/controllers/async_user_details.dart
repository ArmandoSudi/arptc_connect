import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userManagementUserDetailsProvider =
    FutureProvider.family<UserManagementUser, String>((ref, userId) async {
  return ref.read(userManagementRepositoryProvider).fetchUserById(userId);
});
