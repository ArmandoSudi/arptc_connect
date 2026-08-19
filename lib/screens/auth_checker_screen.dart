import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/authentication/screens/account_access_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/login_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/session_loading_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/verify_email_screen.dart';
import 'package:arptc_connect/modules/authentication/screens/initial_password_change_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/courrier_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Legacy entry point retained for callers outside GoRouter. It intentionally
/// uses the same application authorization boundary as protected routes.
class AuthCheckerScreen extends ConsumerWidget {
  const AuthCheckerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(authorizedSessionProvider).status) {
      case AuthenticationStatus.authenticated:
        return const CourrierMainScreen();
      case AuthenticationStatus.initializing:
      case AuthenticationStatus.profileLoading:
        return const SessionLoadingScreen();
      case AuthenticationStatus.emailVerificationRequired:
        return const VerifyEmailScreen();
      case AuthenticationStatus.initialPasswordChangeRequired:
        return const InitialPasswordChangeScreen();
      case AuthenticationStatus.accountDisabled:
      case AuthenticationStatus.failure:
        return const AccountAccessScreen();
      case AuthenticationStatus.unauthenticated:
      case AuthenticationStatus.authenticating:
      case AuthenticationStatus.registrationInProgress:
        return const LoginScreen();
    }
  }
}
