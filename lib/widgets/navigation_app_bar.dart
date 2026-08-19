import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'navigation_title.dart';

class NavigationAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const NavigationAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final session = ref.watch(authorizedSessionProvider).session;
    final userLabel = session?.displayName ?? '';

    return AppBar(
      title: const NavigationTitle(),
      centerTitle: false,
      actions: [
        const NotificationBell(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            userLabel.isEmpty ? l10n.notAvailable : userLabel,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
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
