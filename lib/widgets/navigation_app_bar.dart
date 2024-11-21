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

    return AppBar(
      title: const NavigationTitle(),
      centerTitle: false,
      elevation: 4,
      actions: [
        FutureBuilder(
          future: ref.watch(sharedPrefUtilityProvider).getEmail(),
          builder:
            (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData){
                return Text(snapshot.data!);
              }
              return Text("N/A");
            },
        ),
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
