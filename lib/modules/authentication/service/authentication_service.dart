import 'dart:developer';

import 'package:arptc_connect/modules/administration/domain/models/agent.dart';
import 'package:arptc_connect/utils/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/firebase_providers.dart';
import '../../../core/shared_preferences_provider.dart';

class AuthService {
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  final _providerRef;

  AuthService(this._providerRef){
    _auth = _providerRef.read(firebaseAuthProvider);
    _firestore = _providerRef.read(fireStoreProvider);
  }

  //  This getter will be returning a Stream of User object.
  //  It will be used to check if the user is logged in or not.
  Stream<User?> get authStateChange => _auth.authStateChanges();

  CollectionReference get _agents => _firestore.collection(FirebaseConstants.agentsCollection);
  CollectionReference get users => _firestore.collection(FirebaseConstants.userCollection);


  ///  SignIn the user using Email and Password
  Future<void> signInWithEmailAndPassword(
      String email,
      String password,
      BuildContext? context) async {

    try {
      var result = await _auth.signInWithEmailAndPassword(email: email, password: password);

      //TODO Create an agent in the DB with email as ID
      var agent = await getAgentByEmail(result.user!.email!);
      await getUser(result.user!.email!);
      log("signInWithEmail:: agent ${agent ?? "INEXISTANT"}");

      saveAgent(result.user!.email!);

    } on FirebaseAuthException catch (e) {

      log("signInWithEmail:: ${e.code}");

      if (e.code == 'INVALID_LOGIN_CREDENTIALS') {

        await showDialog(
          context: context! ,
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
          context: context!,
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
  }

  /// SignUp the user using Email and Password
  Future<void> signUpWithEmailAndPassword(
      String email,
      String password,
      BuildContext context) async {

    try {
      var user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // _providerRef.read(asyncUserProvider.notifier).

    } on FirebaseAuthException catch (e) {
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
    await _auth.signOut();
  }

  /// Will send the user an email with a link to reset their password
  Future<void> resetPasswordWithEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print(e);
    }
  }

  Future<Agent?> getAgentByEmail(String email) async {
    try {
      final querySnapshot = await _agents.where('email', isEqualTo: email).get();
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

  Future<void> getUser(String email) async {
    try {

      final documentSnapshot = await users.doc(email).get();

      // Save the user info in the sharedPrefs
      if (documentSnapshot.exists) {

        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;

        log("getUser:: Roles ${data["roles"]}");
        log("getUser:: Roles runtime ${data["roles"].runtimeType}");
        await _providerRef.read(sharedPrefUtilityProvider).setRoles(data["roles"]);
        log("getUser:: User data: $data");
      } else {
        log("getUser:: User does not exist");
      }

    } catch (error) {
      log("Error getUser: $email ::  $error");
      return;
    }
  }

  Future<void> createAgent(Agent) async {
    try {
      await _agents.doc(Agent.email).set(Agent.toJson());
    } catch (error) {
      log("Error createAgent: ${Agent.email} ::  $error");
    }
  }

}
