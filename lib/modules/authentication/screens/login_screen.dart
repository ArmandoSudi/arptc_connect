import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/common_text_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),

                      // Logo
                      Image.asset(
                        'assets/icons/app_logo.png',
                        height: 120,
                      ),
                      const SizedBox(height: 40),

                      // Title
                      Text(
                        "ARPTC CONNECT",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Plateforme integrée de gestion des ressources",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Email
                      CommonTextInput(
                        label: "Email",
                        hintText: "",
                        type: CommonTextInputType.email,
                        controller: emailController,
                        prefixIcon: const Icon(Icons.email),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Email invalide, veuillez votre email professionnel';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password
                      CommonTextInput(
                        label: "Mot de passe",
                        hintText: "",
                        type: CommonTextInputType.text,
                        isPassword: true,
                        controller: passwordController,
                        prefixIcon: const Icon(Icons.lock),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Le mot de passe doit avoir plus de 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            signinWithEmailAndPassword(
                              emailController.text,
                              passwordController.text,
                            );
                          },
                          child: const Text('Se connecter'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Veuillez contacter l'administrateur si votre adresse email n'est pas reconnue",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void signinWithEmailAndPassword(String email, String password) {
    ref
        .read(authServiceProvider)
        .signInWithEmailAndPassword(email, password, context);
  }
}
