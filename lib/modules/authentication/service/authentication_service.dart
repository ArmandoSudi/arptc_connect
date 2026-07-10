import 'dart:developer';

import 'package:arptc_connect/modules/administration/domain/models/agent.dart';
import 'package:arptc_connect/utils/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../../../core/shared_preferences_provider.dart';

class AuthService {
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  final Ref _providerRef;
  bool _isHydratingSession = false;
  String? _hydratedEmail;

  AuthService(this._providerRef) {
    _auth = _providerRef.read(firebaseAuthProvider);
    _firestore = _providerRef.read(fireStoreProvider);
  }

  //  This getter will be returning a Stream of User object.
  //  It will be used to check if the user is logged in or not.
  Stream<User?> get authStateChange => _auth.authStateChanges();

  CollectionReference get _agents =>
      _firestore.collection(FirebaseConstants.agentsCollection);

  ///  SignIn the user using Email and Password
  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    BuildContext? context, {
    bool showErrorDialog = true,
  }) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      //TODO Create an agent in the DB with email as ID
      var agent = await getAgentByEmail(result.user!.email!);
      log("signInWithEmail:: agent ${agent ?? "INEXISTANT"}");

      await saveAgent(result.user!.email!);
    } on FirebaseAuthException catch (e) {
      log("signInWithEmail:: ${e.code}");
      if (!showErrorDialog) {
        rethrow;
      }
      final safeContext = context;
      if (safeContext == null || !safeContext.mounted) {
        return;
      }

      if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        await showDialog(
          context: safeContext,
          builder: (ctx) => AlertDialog(
            title: const Text('Une erreur est survenue'),
            content: const Text("Email ou Mot de Passe incorrect"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text("OK"))
            ],
          ),
        );
      } else {
        await showDialog(
          context: safeContext,
          builder: (ctx) => AlertDialog(
            title: const Text('Une erreur est survenue'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text("OK"))
            ],
          ),
        );
      }
    }
  }

  Future<void> saveAgent(String email) async {
    await _providerRef.read(sharedPrefUtilityProvider).setEmail(email);
    await cacheAgentProfileByEmail(email);
  }

  Future<void> warmLocalSessionIfNeeded(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return;
    }

    final sharedPref = _providerRef.read(sharedPrefUtilityProvider);
    final cachedEmail = (await sharedPref.getEmail()).trim().toLowerCase();
    final cachedProfile = sharedPref.getAgentProfile();

    final profileEmailLower =
        (cachedProfile['emailLower'] ?? cachedProfile['email'])
            ?.toString()
            .trim()
            .toLowerCase();
    final hasMatchingProfile = cachedProfile.isNotEmpty &&
        profileEmailLower != null &&
        profileEmailLower == normalizedEmail;
    final hasSameEmail = cachedEmail == normalizedEmail;

    if (hasSameEmail && hasMatchingProfile) {
      _hydratedEmail = normalizedEmail;
      return;
    }

    if (_isHydratingSession && _hydratedEmail == normalizedEmail) {
      return;
    }
    if (_isHydratingSession) {
      return;
    }

    _isHydratingSession = true;
    try {
      await _providerRef.read(sharedPrefUtilityProvider).setEmail(email.trim());
      await cacheAgentProfileByEmail(email.trim());
      _hydratedEmail = normalizedEmail;
    } finally {
      _isHydratingSession = false;
    }
  }

  /// SignUp the user using Email and Password
  Future<void> signUpWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // _providerRef.read(asyncUserProvider.notifier).
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) {
        return;
      }
      await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Error Occured'),
                  content: Text(e.toString()),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const Text("OK"))
                  ]));
    } catch (e) {
      if (e == 'email-already-in-use') {
        if (!context.mounted) {
          return;
        }
        await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: const Text('Erreur'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          child: const Text("OK"))
                    ]));
        log('Email already in use.');
      } else {
        log('Error: $e');
      }
    }
  }

  /// Log the user out of the app and return to the login screen
  Future<void> signOut() async {
    _hydratedEmail = null;
    await _providerRef.read(sharedPrefUtilityProvider).clearSession();
    await _auth.signOut();
  }

  /// Will send the user an email with a link to reset their password
  Future<void> resetPasswordWithEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      log('resetPasswordWithEmail error => $e');
    }
  }

  Future<Agent?> getAgentByEmail(String email) async {
    try {
      final querySnapshot =
          await _agents.where('email', isEqualTo: email).get();
      if (querySnapshot.docs.isNotEmpty) {
        return Agent.fromDocument(querySnapshot.docs.first);
      } else {
        return null;
      }
    } catch (error) {
      log("Error getAgetnByEmail: $email ::  $error");
      return null;
    }
  }

  Future<void> createAgent(Agent agent) async {
    try {
      await _agents.doc(agent.email).set(agent.toJson());
    } catch (error) {
      log("Error createAgent: ${agent.email} ::  $error");
    }
  }

  Future<void> cacheAgentProfileByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return;
    }

    try {
      QuerySnapshot byEmailLower =
          await _agents.where('emailLower', isEqualTo: normalizedEmail).get();

      if (byEmailLower.docs.isEmpty) {
        byEmailLower =
            await _agents.where('email', isEqualTo: email.trim()).get();
      }

      if (byEmailLower.docs.isEmpty) {
        log("cacheAgentProfileByEmail:: no agent found for $email");
        await _providerRef.read(sharedPrefUtilityProvider).clearAgentProfile();
        return;
      }

      final document = _pickPreferredAgentDocument(
            byEmailLower.docs,
            normalizedEmail: normalizedEmail,
          ) ??
          byEmailLower.docs.first;
      final raw = document.data() as Map<String, dynamic>;
      final serialized = _toSerializableMap(raw);
      serialized['id'] = document.id;
      serialized['email'] = (serialized['email'] ?? email).toString();
      serialized['emailLower'] = serialized['email'].toString().toLowerCase();

      await _providerRef.read(sharedPrefUtilityProvider).setAgentProfile(
            serialized,
          );
    } catch (error) {
      log("cacheAgentProfileByEmail:: error for $email => $error");
    }
  }

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

  QueryDocumentSnapshot? _pickPreferredAgentDocument(
    List<QueryDocumentSnapshot> docs, {
    required String normalizedEmail,
  }) {
    if (docs.isEmpty) {
      return null;
    }

    final sorted = [...docs];
    sorted.sort((left, right) {
      final leftData = _asMap(left.data());
      final rightData = _asMap(right.data());

      final emailComparison = _emailMatchScore(rightData, normalizedEmail)
          .compareTo(_emailMatchScore(leftData, normalizedEmail));
      if (emailComparison != 0) {
        return emailComparison;
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

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  int _emailMatchScore(Map<String, dynamic> data, String normalizedEmail) {
    final normalizedFromLower =
        data['emailLower']?.toString().trim().toLowerCase() ?? '';
    if (normalizedFromLower == normalizedEmail) {
      return 1;
    }

    final normalizedFromEmail =
        data['email']?.toString().trim().toLowerCase() ?? '';
    if (normalizedFromEmail == normalizedEmail) {
      return 1;
    }

    return 0;
  }

  int _activeScore(Map<String, dynamic> data) {
    final value = data['isActive'];
    if (value is bool) {
      return value ? 1 : 0;
    }
    return 1;
  }

  int _dateScore(Map<String, dynamic> data, String field) {
    final value = data[field];
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
}
