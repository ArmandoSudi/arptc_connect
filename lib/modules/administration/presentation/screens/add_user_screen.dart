import 'dart:developer';

import 'package:arptc_connect/modules/administration/domain/models/user.dart';
import 'package:arptc_connect/modules/administration/presentation/controllers/async_user.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/custom_form_field.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {

  TextEditingController nameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController roleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                    const Gap(16),
                    const PageHeader(
                      title: 'Créer un utilisateur',
                      description:
                      'Remplissez le formulaire pour créer un nouvel utilisateur',
                    ),
                  ],
                ),
                const Gap(16),
                ResponsiveCenter(
                  child: Column(
                    children: [
                      CustomFormField(
                        label: "Prénom",
                        hintText: "Prénom de l'utilisateur",
                        textInputType: TextInputType.name,
                        controller: firstNameController,
                      ),
                      const Gap(16),
                      CustomFormField(
                        label: "Nom",
                        hintText: "Nom de l'utilisateur",
                        textInputType: TextInputType.name,
                        controller: nameController,
                      ),
                      const Gap(16),
                      CustomFormField(
                        label: "Email",
                        hintText: "Email de l'utilisateur",
                        textInputType: TextInputType.name,
                        controller: emailController,
                      ),
                      const Gap(16),
                      CustomFormField(
                        label: "Rôles",
                        hintText: "Rôle de l'utilisateur",
                        textInputType: TextInputType.name,
                        controller: roleController,
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: CustomFilledButton(
                onPressed: () {

                  createUser(User(
                      firstName: firstNameController.text,
                      name: nameController.text,
                      email: emailController.text,
                      roles: ["inventory", "admin", "social"]),
                    "Arptc@1234"
                  );

                  ref.read(asyncUserProvider.notifier).addUser(
                    User(
                        firstName: firstNameController.text,
                        name: nameController.text,
                        email: emailController.text,
                        roles: ["inventory", "admin", "social"])
                  );
                  context.pop();
                },
                text: "Enregistrer",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  log("add_direction_screen:: cancel");
                },
                child: const Text("Annuler",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void createUser(User user, String password) async {
    ref
        .read(authServiceProvider)
        .signUpWithEmailAndPassword(user.email, password, context);
  }
}
