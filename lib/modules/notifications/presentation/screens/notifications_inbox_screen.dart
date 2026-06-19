import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/notifications/data/firestore_notification_repository.dart';
import 'package:arptc_connect/modules/notifications/domain/app_notification.dart';
import 'package:arptc_connect/modules/notifications/presentation/controllers/notification_providers.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationsInboxScreen extends ConsumerWidget {
  const NotificationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(notificationInboxProvider);
    final l10n = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
      ),
      body: inboxAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return EmptyStateView(
              icon: Icons.notifications_none_outlined,
              title: l10n.noNotificationsYet,
              description: l10n.noNotificationsDescription,
            );
          }

          return ResponsiveCenter(
            maxContentWidth: 920,
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
        loading: () => LoadingStateView(
          message: l10n.loadingNotifications,
        ),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoadNotifications,
          description: error.toString(),
          onRetry: () {
            ref.invalidate(personalNotificationsProvider);
            ref.invalidate(globalNotificationsProvider);
            ref.invalidate(globalNotificationReadIdsProvider);
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final createdAt = notification.createdAt;
    final l10n = S.of(context);

    return Card(
      elevation: notification.isRead ? 0 : 1,
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withOpacity(0.38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: notification.isRead
              ? colorScheme.outlineVariant
              : colorScheme.primary.withOpacity(0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openNotification(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconForModule(notification.moduleKey),
                  color: notification.isRead
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ChipLabel(
                          label: _moduleLabel(notification.moduleKey, l10n),
                          icon: Icons.apps_outlined,
                        ),
                        _ChipLabel(
                          label: notification.isGlobal
                              ? l10n.everyone
                              : l10n.forYou,
                          icon: notification.isGlobal
                              ? Icons.campaign_outlined
                              : Icons.person_outline,
                        ),
                        if (createdAt != null)
                          _ChipLabel(
                            label: DateFormat('MMM d, HH:mm').format(createdAt),
                            icon: Icons.schedule_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNotification(BuildContext context, WidgetRef ref) async {
    final agentId = ref.read(currentNotificationAgentIdProvider).valueOrNull;
    if (agentId != null && agentId.isNotEmpty && !notification.isRead) {
      final repository = ref.read(notificationRepositoryProvider);
      if (notification.isGlobal) {
        await repository.markGlobalNotificationRead(
          agentId: agentId,
          notificationId: notification.id,
        );
      } else {
        await repository.markPersonalNotificationRead(
          agentId: agentId,
          notificationId: notification.id,
        );
      }
    }

    if (!context.mounted || notification.route.isEmpty) {
      return;
    }
    context.go(notification.route);
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForModule(String moduleKey) {
  switch (moduleKey.toLowerCase()) {
    case 'news':
      return Icons.feed_outlined;
    case 'ticketing':
    case 'incident':
    case 'incidents':
      return Icons.confirmation_number_outlined;
    default:
      return Icons.notifications_none_outlined;
  }
}

String _moduleLabel(String moduleKey, S l10n) {
  switch (moduleKey.toLowerCase()) {
    case 'news':
      return l10n.news;
    case 'ticketing':
    case 'incident':
    case 'incidents':
      return l10n.incidentSupport;
    default:
      return moduleKey.isEmpty ? l10n.erp : moduleKey;
  }
}
