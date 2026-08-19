import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/core/shared_preferences_provider.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/utils/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cachedAgentProfileProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final sharedPref = ref.read(sharedPrefUtilityProvider);
    final authState = ref.watch(authStateProvider);
    final authUser =
        authState.valueOrNull ?? ref.read(firebaseAuthProvider).currentUser;
    final cached = sharedPref.getAgentProfile();

    if (authState.isLoading && authUser == null) {
      return <String, dynamic>{};
    }

    if (authState.hasValue && authUser == null) {
      await sharedPref.clearAgentProfile();
      return <String, dynamic>{};
    }
    if (authUser == null) {
      await sharedPref.clearAgentProfile();
      return <String, dynamic>{};
    }

    final cachedEmail = (await sharedPref.getEmail()).trim();
    final authEmail = authUser.email?.trim() ?? '';
    final email = authEmail.isNotEmpty ? authEmail : cachedEmail;

    if (cached.isNotEmpty && _profileMatchesIdentity(cached, authUser)) {
      return cached;
    }

    if (email.isNotEmpty && cachedEmail.toLowerCase() != email.toLowerCase()) {
      await sharedPref.setEmail(email);
    }

    if (email.isNotEmpty) {
      await ref.read(authServiceProvider).cacheAgentProfileByEmail(email);
    }

    return sharedPref.getAgentProfile();
  },
);

final liveAgentProfileProvider = StreamProvider<Map<String, dynamic>>(
  (ref) async* {
    final sharedPref = ref.read(sharedPrefUtilityProvider);
    final authState = ref.watch(authStateProvider);
    final authUser =
        authState.valueOrNull ?? ref.read(firebaseAuthProvider).currentUser;

    if (authState.isLoading && authUser == null) {
      return;
    }

    if (authState.hasValue && authUser == null) {
      await sharedPref.clearAgentProfile();
      yield <String, dynamic>{};
      return;
    }
    if (authUser == null) {
      await sharedPref.clearAgentProfile();
      yield <String, dynamic>{};
      return;
    }

    final cachedEmail = (await sharedPref.getEmail()).trim();
    final authEmail = authUser.email?.trim() ?? '';
    final email = authEmail.isNotEmpty ? authEmail : cachedEmail;

    if (email.isEmpty) {
      yield <String, dynamic>{};
      return;
    }

    if (cachedEmail.toLowerCase() != email.toLowerCase()) {
      await sharedPref.setEmail(email);
    }

    final firestore = ref.read(fireStoreProvider);
    final collection = firestore.collection(FirebaseConstants.agentsCollection);

    await for (final document in collection.doc(authUser.uid).snapshots()) {
      if (!document.exists || document.data() == null) {
        await sharedPref.clearAgentProfile();
        yield <String, dynamic>{};
        continue;
      }

      final data = _toSerializableMap(_docDataAsMap(document.data()));
      data['id'] = document.id;
      data['email'] = (data['email'] ?? email).toString().trim();
      data['emailLower'] = data['email'].toString().toLowerCase();

      await sharedPref.setAgentProfile(data);
      yield data;
    }
  },
);

Map<String, dynamic> _toSerializableMap(Map<String, dynamic> raw) {
  final serialized = <String, dynamic>{};
  raw.forEach((key, value) {
    serialized[key] = _toSerializableValue(value);
  });
  return serialized;
}

dynamic _toSerializableValue(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is List) {
    return value.map(_toSerializableValue).toList();
  }
  if (value is Map) {
    final nested = <String, dynamic>{};
    value.forEach((key, nestedValue) {
      nested[key.toString()] = _toSerializableValue(nestedValue);
    });
    return nested;
  }
  return value.toString();
}

Map<String, dynamic> _docDataAsMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return <String, dynamic>{};
}

bool _profileMatchesIdentity(
  Map<String, dynamic> profile,
  Object? authUser,
) {
  if (authUser is! User) {
    return false;
  }

  final normalizedEmail = authUser.email?.trim().toLowerCase() ?? '';
  final cachedId = profile['id']?.toString().trim() ?? '';
  return normalizedEmail.isNotEmpty &&
      cachedId == authUser.uid &&
      _emailMatchScore(profile, normalizedEmail) > 0;
}

int _emailMatchScore(Map<String, dynamic> data, String normalizedEmail) {
  final candidates = [
    data['emailLower'],
    data['email'],
  ];

  for (final candidate in candidates) {
    final normalized = candidate?.toString().trim().toLowerCase() ?? '';
    if (normalized == normalizedEmail) {
      return 1;
    }
  }

  return 0;
}
