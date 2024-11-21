import 'dart:developer';
import 'dart:convert';

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

  Future<String> getEmail() async {
    return sharedPreferences.getString('email') ?? '';
  }

  void setEmail(String email) async {
    await sharedPreferences.setString('email', email);
    log("EMAIL : $email SAVED");
  }

  Future<String> getName() async {
    return sharedPreferences.getString('name') ?? '';
  }

  void setName(String name) {
    sharedPreferences.setString('name', name);
  }

  void setRoles(List<dynamic> roles) async {
    final _roles = roles.map((e) => e.toString()).toList();
    String encodedList = jsonEncode(_roles);
    sharedPreferences.setString('roles', encodedList);
  }

  List<String> getRoles(){

    var encodedList = sharedPreferences.getString('roles');

    // If the string exists, decode it into a list of strings
    if (encodedList != null) {
      List<dynamic> jsonResponse = jsonDecode(encodedList);
      return List<String>.from(jsonResponse);
    }

    return [];
  }



}