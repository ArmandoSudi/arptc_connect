
import 'dart:developer';

import 'package:arptc_connect/core/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../modules/authentication/providers/authentication_provider.dart';
import 'navigation_title.dart';

class NavigationAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const NavigationAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    String email = ref.watch(sharedPrefUtilityProvider).getEmail();

    log("NavigationAppBar Email::  $email");

    return AppBar(
      title: const NavigationTitle(),
      centerTitle: false,
      elevation: 4,
      actions: [
        Text(email),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: PopupMenuButton<void>(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Sign out'),
                onTap: () {
                  // Sign out logic
                  ref.read(authServiceProvider).signOut();
                },
              ),
            ],
            child: const Icon(Icons.account_circle_outlined),
          ),
        ),
        const Gap(8),
      ],
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
}