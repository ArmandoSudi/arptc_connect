import 'package:arptc_connect/screens/home_screen.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[200],
        child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/icons/app_logo.png',
                        height: 120,
                      ),
                      const SizedBox(height: 40),
                      const Text("ARPTC CONNECT", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text("Plateforme integrée de gestion des ressources "),
                      const SizedBox(height: 40),
                      CustomFormField(
                        label: "Email",
                        hintText: "...@arptc.gouv.cd",
                        textInputType: TextInputType.emailAddress,
                        controller: emailController,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: (){
                          Navigator
                              .of(context)
                              .push(MaterialPageRoute(builder: (context) => HomeScreen()));
                        },
                        child: Text("Login"),
                      ),
                      const SizedBox(height: 20),
                      const Text("Veuillez contacter l'administrateur si votre numéro n'est pas reconnu", style: TextStyle(fontSize: 10,)),
                    ],
                  ),
                ),
              ),
            )),
      ),
    );
  }
}