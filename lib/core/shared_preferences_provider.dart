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

  Future<void> setEmail(String email) async {
    await sharedPreferences.setString('email', email);
    log("EMAIL : $email SAVED");
  }

  Future<String> getName() async {
    return sharedPreferences.getString('name') ?? '';
  }

  void setName(String name) {
    sharedPreferences.setString('name', name);
  }

  Future<void> setAgentProfile(Map<String, dynamic> profile) async {
    final encoded = jsonEncode(profile);
    await sharedPreferences.setString('agent_profile', encoded);
  }

  Map<String, dynamic> getAgentProfile() {
    final encoded = sharedPreferences.getString('agent_profile');
    if (encoded == null || encoded.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(encoded);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  Future<void> clearAgentProfile() async {
    await sharedPreferences.remove('agent_profile');
  }

  Future<void> clearSession() async {
    await sharedPreferences.remove('email');
    await sharedPreferences.remove('agent_profile');
  }
}
