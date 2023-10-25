import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/authentication/service/authentication_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

class AuthController {
  final AuthService _authenticationService;

  AuthController(this._authenticationService);

  void signWithEmailAndPassword(String email, String password) {
    _authenticationService.signInWithEmailAndPassword(email, password, null);
  }
}