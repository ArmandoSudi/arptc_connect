import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_providers.dart';
import '../service/authentication_service.dart';

/// The provider for the authentication class providing all if its features
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});


/// Getting the state of authentication through the provider.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChange;
});

