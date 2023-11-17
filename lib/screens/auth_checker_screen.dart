import 'package:arptc_connect/modules/authentication/screens/login_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/courrier_base_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/courrier_main_screen.dart';
import 'package:arptc_connect/modules/courrier/screens/list_courriers_screen.dart';
import 'package:arptc_connect/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modules/authentication/providers/authentication_provider.dart';

class AuthCheckerScreen extends ConsumerWidget {
  const AuthCheckerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Constantly checking the authentication state
    final _authState = ref.watch(authStateProvider);

    // return _authState.when(
    //     data: (data) {
    //       if (data != null) return const HomeScreen();
    //       return const LoginScreen();
    //     },
    //     loading: () => const Center(child: CupertinoActivityIndicator()),
    //     error: (e, trace) => Center(child: Column(
    //       children: [
    //         Text(e.toString()),
    //         Text(trace.toString()),
    //       ],
    //     )));

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: ref.read(authServiceProvider).authStateChange,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            // return const ListCourriersScreen();
            return const CourrierMainScreen();
          } else if(snapshot.connectionState == ConnectionState.waiting){
            return const CupertinoActivityIndicator();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}



