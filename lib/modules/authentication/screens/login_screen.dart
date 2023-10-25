import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/custom_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Container(
          color: Colors.grey[200],
          child: Center(
              child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Logo
                    Image.asset(
                      'assets/icons/app_logo.png',
                      height: 120,
                    ),
                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      "ARPTC CONNECT",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                        "Plateforme integrée de gestion des ressources "),
                    const SizedBox(height: 40),

                    // Email
                    CustomFormField(
                      label: "Email",
                      hintText: "",
                      textInputType: TextInputType.emailAddress,
                      controller: emailController,
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Email invalide, veuillez votre email professionnel';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password
                    CustomFormField(
                      label: "Password",
                      hintText: "",
                      textInputType: TextInputType.text,
                      obscureText: true,
                      maxLine: 1,
                      controller: passwordController,
                      validator: (value) {
                        if (value!.isEmpty || value.length < 6) {
                          return 'Le mot de passe doit avoir plus de 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Login Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        signinWithEmailAndPassword(emailController.text,
                          passwordController.text);
                      },
                      child: const Text("Login"),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                        "Veuillez contacter l'administrateur si votre numéro n'est pas reconnu",
                        style: TextStyle(
                          fontSize: 10,
                        )), 
                  ],
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }

  void signinWithEmailAndPassword(String email, String password) {
    ref.read(authServiceProvider).signInWithEmailAndPassword(email, password, context);
  }
}
