import 'package:arptc_connect/core/shared_preferences_provider.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../modules/authentication/providers/authentication_provider.dart';
import 'navigation_title.dart';

class NavigationAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const NavigationAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);

    return AppBar(
      title: const NavigationTitle(),
      centerTitle: false,
      elevation: 4,
      actions: [
        const NotificationBell(),
        FutureBuilder(
          future: ref.watch(sharedPrefUtilityProvider).getEmail(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!);
            }
            return Text(l10n.notAvailable);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: PopupMenuButton<void>(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(l10n.signOut),
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
