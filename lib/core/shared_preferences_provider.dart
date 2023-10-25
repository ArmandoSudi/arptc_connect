import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final sharedPrefUtilityProvider = Provider<SharedPrefUtility>((ref) {
  final sharedPref = ref.watch(sharedPrefProvider);
  return SharedPrefUtility(sharedPreferences: sharedPref);
});

class SharedPrefUtility {
  SharedPrefUtility({
    required this.sharedPreferences,
  });

  final SharedPreferences sharedPreferences;

  String getEmail() {
    return sharedPreferences.getString('email') ?? '';
  }

  void setEmail(String email) {
    sharedPreferences.setString('email', email);
  }

  String getName() {
    return sharedPreferences.getString('name') ?? '';
  }

  void setName(String name) {
    sharedPreferences.setString('name', name);
  }

}