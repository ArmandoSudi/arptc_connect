import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/core/shared_preferences_provider.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/utils/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cachedAgentProfileProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final sharedPref = ref.read(sharedPrefUtilityProvider);
    final authState = ref.watch(authStateProvider);
    final authUser =
        authState.valueOrNull ?? ref.read(firebaseAuthProvider).currentUser;
    final cached = sharedPref.getAgentProfile();

    if (authState.isLoading && authUser == null) {
      return cached;
    }

    if (authState.hasValue && authUser == null) {
      await sharedPref.clearAgentProfile();
      return <String, dynamic>{};
    }

    final cachedEmail = (await sharedPref.getEmail()).trim();
    final authEmail = authUser?.email?.trim() ?? '';
    final email = authEmail.isNotEmpty ? authEmail : cachedEmail;

    if (cached.isNotEmpty && _profileMatchesEmail(cached, email)) {
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
    final cached = sharedPref.getAgentProfile();

    if (authState.isLoading && authUser == null) {
      if (cached.isNotEmpty) {
        yield cached;
      }
      return;
    }

    if (authState.hasValue && authUser == null) {
      await sharedPref.clearAgentProfile();
      yield <String, dynamic>{};
      return;
    }

    final cachedEmail = (await sharedPref.getEmail()).trim();
    final authEmail = authUser?.email?.trim() ?? '';
    final email = authEmail.isNotEmpty ? authEmail : cachedEmail;

    if (cached.isNotEmpty && _profileMatchesEmail(cached, email)) {
      yield cached;
    }

    if (email.isEmpty) {
      if (cached.isEmpty) {
        yield <String, dynamic>{};
      }
      return;
    }

    if (cachedEmail.toLowerCase() != email.toLowerCase()) {
      await sharedPref.setEmail(email);
    }

    final firestore = ref.read(fireStoreProvider);
    final normalizedEmail = email.toLowerCase();
    final collection = firestore.collection(FirebaseConstants.agentsCollection);

    final byEmailLowerQuery =
        collection.where('emailLower', isEqualTo: normalizedEmail);
    final byEmailQuery = collection.where('email', isEqualTo: email);

    final initialByEmailLower = await byEmailLowerQuery.get();
    final sourceStream = initialByEmailLower.docs.isNotEmpty
        ? byEmailLowerQuery.snapshots()
        : byEmailQuery.snapshots();

    await for (final snapshot in sourceStream) {
      final document = _pickPreferredAgentDoc(snapshot.docs,
          normalizedEmail: normalizedEmail);
      if (document == null) {
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

QueryDocumentSnapshot<Object?>? _pickPreferredAgentDoc(
  List<QueryDocumentSnapshot<Object?>> docs, {
  required String normalizedEmail,
}) {
  if (docs.isEmpty) {
    return null;
  }

  final sorted = [...docs];
  sorted.sort((left, right) {
    final leftData = _docDataAsMap(left.data());
    final rightData = _docDataAsMap(right.data());

    final emailMatchComparison = _emailMatchScore(rightData, normalizedEmail)
        .compareTo(_emailMatchScore(leftData, normalizedEmail));
    if (emailMatchComparison != 0) {
      return emailMatchComparison;
    }

    final activeComparison =
        _activeScore(rightData).compareTo(_activeScore(leftData));
    if (activeComparison != 0) {
      return activeComparison;
    }

    final updatedComparison = _dateScore(rightData, 'updatedAt')
        .compareTo(_dateScore(leftData, 'updatedAt'));
    if (updatedComparison != 0) {
      return updatedComparison;
    }

    final createdComparison = _dateScore(rightData, 'createdAt')
        .compareTo(_dateScore(leftData, 'createdAt'));
    if (createdComparison != 0) {
      return createdComparison;
    }

    return right.id.compareTo(left.id);
  });

  return sorted.first;
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

bool _profileMatchesEmail(Map<String, dynamic> profile, String email) {
  final normalizedEmail = email.trim().toLowerCase();
  if (normalizedEmail.isEmpty) {
    return true;
  }

  return _emailMatchScore(profile, normalizedEmail) > 0;
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

int _activeScore(Map<String, dynamic> data) {
  final raw = data['isActive'];
  if (raw is bool) {
    return raw ? 1 : 0;
  }
  return 1;
}

int _dateScore(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }
  if (value is DateTime) {
    return value.millisecondsSinceEpoch;
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.millisecondsSinceEpoch;
    }
  }
  return 0;
}
