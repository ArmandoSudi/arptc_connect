import 'package:arptc_connect/modules/notifications/presentation/controllers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(notificationUnreadCountProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.go('/home/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_outlined),
          if (unreadCount > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
