import 'dart:developer';

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
  Stream<User?> get authStateChange async* {
    await for (final user in _auth.userChanges()) {
      if (user != null && !user.emailVerified) {
        try {
          yield await _bootstrapInitialPasswordChange(user);
          continue;
        } catch (error) {
          // Non-agent registrations retain the existing email-verification
          // path. Valid manager-provisioned agents are upgraded by the callable.
          log('Initial password bootstrap skipped: $error');
        }
      }
      yield user;
    }
  }

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
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = await _bootstrapInitialPasswordChange(result.user!);
      // Ensure Firestore sees the newly authenticated identity before any
      // profile listener starts evaluating role-based rules.
      await user.getIdToken(true);
      await saveAgent(user.email!);
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
    final authUser = _auth.currentUser;
    final authUserId = authUser?.uid.trim() ?? '';
    final authUserEmail = authUser?.email?.trim().toLowerCase() ?? '';

    if (authUserId.isEmpty || authUserEmail != normalizedEmail) {
      await sharedPref.clearSession();
      return;
    }

    final profileEmailLower =
        (cachedProfile['emailLower'] ?? cachedProfile['email'])
            ?.toString()
            .trim()
            .toLowerCase();
    final hasMatchingProfile = cachedProfile.isNotEmpty &&
        profileEmailLower != null &&
        profileEmailLower == normalizedEmail &&
        cachedProfile['id']?.toString().trim() == authUserId;
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
      await sendEmailVerification();
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

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) {
      return;
    }
    await user.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> completeInitialPasswordChange(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'A signed-in account is required.',
      );
    }
    final callable = _providerRef
        .read(firebaseFunctionsProvider)
        .httpsCallable('completeInitialPasswordChange');
    await callable.call<void>({'newPassword': newPassword});
    _hydratedEmail = null;
    await _providerRef.read(sharedPrefUtilityProvider).clearSession();
    await _auth.signOut();
  }

  Future<User> _bootstrapInitialPasswordChange(User user) async {
    if (user.emailVerified) {
      return user;
    }
    final callable = _providerRef
        .read(firebaseFunctionsProvider)
        .httpsCallable('bootstrapInitialPasswordChange');
    await callable.call<void>();
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser ?? user;
  }

  Future<void> cacheAgentProfileByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return;
    }

    try {
      final authUser = _auth.currentUser;
      final authEmail = authUser?.email?.trim().toLowerCase() ?? '';
      final userId = authUser?.uid.trim() ?? '';
      if (userId.isEmpty || authEmail != normalizedEmail) {
        await _providerRef.read(sharedPrefUtilityProvider).clearAgentProfile();
        return;
      }

      final document = await _agents.doc(userId).get();
      if (!document.exists || document.data() == null) {
        log("cacheAgentProfileByEmail:: no UID agent found for $email");
        await _providerRef.read(sharedPrefUtilityProvider).clearAgentProfile();
        return;
      }

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
      await _providerRef.read(sharedPrefUtilityProvider).clearAgentProfile();
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
}
