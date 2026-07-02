import 'dart:convert';

import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/notifications/data/notification_messaging_service.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(liveAgentProfileProvider);
    final theme = Theme.of(context);
    final l10n = S.of(context);

    return ContentView(
      child: profileAsync.when(
        data: (profile) {
          if (profile.isEmpty) {
            return ErrorStateView(
              title: l10n.profileUnavailable,
              description: l10n.profileUnavailableDescription,
              onRetry: () => ref.invalidate(liveAgentProfileProvider),
            );
          }

          final pictureUrl = _firstNonEmptyString(
            profile,
            const [
              'profilePictureUrl',
              'photoUrl',
              'photoURL',
              'avatarUrl',
              'imageUrl',
            ],
          );
          final fullName = _buildDisplayName(profile, fallback: l10n.agent);
          final email = _valueAsString(profile['email']);
          final entries = _buildFieldEntries(profile, l10n);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: l10n.profile,
                  description: l10n.connectedAgentInformation,
                ),
                const SizedBox(height: 16),
                _NotificationPermissionCard(profile: profile),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundImage: pictureUrl == null
                              ? null
                              : NetworkImage(pictureUrl),
                          child: pictureUrl == null
                              ? Text(
                                  _initials(fullName),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email.isEmpty ? l10n.noEmail : email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _valueAsString(profile['position']),
                                style: theme.textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.agentInformation,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (entries.isEmpty)
                          EmptyStateView(
                            icon: Icons.info_outline,
                            title: l10n.noFields,
                            description: l10n.noProfileFieldsAvailable,
                          )
                        else
                          ...entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _InfoRow(
                                label: entry.key,
                                value: entry.value,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomFilledButton(
                        text: l10n.refreshProfile,
                        onPressed: () {
                          ref.invalidate(liveAgentProfileProvider);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authServiceProvider).signOut();
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.signOut),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoadProfile,
          description: error.toString(),
          onRetry: () => ref.invalidate(liveAgentProfileProvider),
        ),
        loading: () => LoadingStateView(message: l10n.loadingProfile),
      ),
    );
  }
}

class _NotificationPermissionCard extends ConsumerStatefulWidget {
  const _NotificationPermissionCard({
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  ConsumerState<_NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState
    extends ConsumerState<_NotificationPermissionCard> {
  AuthorizationStatus? _status;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEnabled =>
      _status == AuthorizationStatus.authorized ||
      _status == AuthorizationStatus.provisional;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ref
          .read(notificationMessagingServiceProvider)
          .currentAuthorizationStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = AuthorizationStatus.notDetermined;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = S.of(context);
    final service = ref.watch(notificationMessagingServiceProvider);
    final missingConfiguration = !service.hasRequiredConfiguration;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: CheckboxListTile(
          value: _isEnabled,
          onChanged: _isLoading || _isSaving
              ? null
              : (value) {
                  if (value == true) {
                    _enableNotificationsFromUserAction();
                  } else {
                    _showDisableInstructions();
                  }
                },
          secondary: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _isEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  color: _isEnabled ? theme.colorScheme.primary : null,
                ),
          title: Text(
            l10n.enableNotifications,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            missingConfiguration
                ? l10n.webPushNotConfiguredDescription
                : _statusLabel(l10n, _status, service.clientPlatform),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  Future<void> _enableNotificationsFromUserAction() async {
    final service = ref.read(notificationMessagingServiceProvider);
    if (!service.hasRequiredConfiguration) {
      await _showMessageDialog(
        title: S.of(context).webPushNotConfigured,
        message: S.of(context).webPushNotConfiguredAction,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authUser = ref.read(firebaseAuthProvider).currentUser;
      final status = await service.requestPermissionAndRegisterForAgent(
        profile: widget.profile,
        fallbackUserId: authUser?.uid ?? '',
      );

      if (!mounted) return;
      setState(() {
        _status = status;
      });

      final messenger = ScaffoldMessenger.of(context);
      if (_isPermissionGranted(status)) {
        messenger.showSnackBar(
          SnackBar(content: Text(S.of(context).notificationsEnabled)),
        );
      } else if (status == AuthorizationStatus.denied) {
        await _showNotificationBlockedInstructions();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(S.of(context).notificationPermissionNotGranted),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog(
        title: S.of(context).unableToEnableNotifications,
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showDisableInstructions() async {
    final platform =
        ref.read(notificationMessagingServiceProvider).clientPlatform;
    await _showMessageDialog(
      title: S.of(context).disableNotifications,
      message: _disableNotificationInstructions(S.of(context), platform),
    );
  }

  Future<void> _showNotificationBlockedInstructions() async {
    final platform =
        ref.read(notificationMessagingServiceProvider).clientPlatform;
    await _showMessageDialog(
      title: S.of(context).notificationsBlocked,
      message: _blockedNotificationInstructions(S.of(context), platform),
    );
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(S.of(dialogContext).ok),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

List<MapEntry<String, String>> _buildFieldEntries(
  Map<String, dynamic> profile,
  S l10n,
) {
  const orderedKeys = [
    'id',
    'firstName',
    'name',
    'postName',
    'matricule',
    'email',
    'position',
    'departmentId',
    'serviceId',
    'bureauId',
    'isActive',
    'modulePermissions',
    'genre',
    'dob',
    'category',
    'direction',
    'service',
    'bureau',
    'createdAt',
    'updatedAt',
  ];

  final entries = <MapEntry<String, String>>[];
  final consumedKeys = <String>{};

  for (final key in orderedKeys) {
    if (!profile.containsKey(key)) {
      continue;
    }
    consumedKeys.add(key);
    entries.add(
      MapEntry(_profileFieldLabel(key, l10n), _stringifyValue(profile[key])),
    );
  }

  final extraKeys =
      profile.keys.where((key) => !consumedKeys.contains(key)).toList()..sort();

  for (final key in extraKeys) {
    entries.add(
      MapEntry(_profileFieldLabel(key, l10n), _stringifyValue(profile[key])),
    );
  }

  return entries;
}

String _profileFieldLabel(String key, S l10n) {
  switch (key) {
    case 'firstName':
      return l10n.firstName;
    case 'name':
      return l10n.name;
    case 'postName':
      return l10n.postName;
    case 'matricule':
      return l10n.matricule;
    case 'email':
      return l10n.email;
    case 'position':
      return l10n.position;
    case 'departmentId':
    case 'department':
    case 'direction':
      return l10n.department;
    case 'serviceId':
    case 'service':
      return l10n.service;
    case 'bureauId':
    case 'bureau':
      return l10n.bureau;
    case 'isActive':
      return l10n.active;
    case 'modulePermissions':
      return l10n.modulePermissions;
    case 'category':
      return l10n.category;
    case 'createdAt':
      return l10n.createdAt;
    case 'updatedAt':
      return l10n.updatedAt;
    default:
      return _prettyLabel(key);
  }
}

String _prettyLabel(String key) {
  final normalized = key.replaceAll(RegExp(r'[_\-]'), ' ');
  if (normalized.isEmpty) {
    return key;
  }

  final words = normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) {
    return key;
  }

  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _buildDisplayName(
  Map<String, dynamic> data, {
  required String fallback,
}) {
  final pieces = [
    _valueAsString(data['firstName']),
    _valueAsString(data['name']),
    _valueAsString(data['postName']),
  ].where((piece) => piece.isNotEmpty).toList();

  if (pieces.isNotEmpty) {
    return pieces.join(' ');
  }

  final legacyName = _valueAsString(data['name']);
  if (legacyName.isNotEmpty) {
    return legacyName;
  }

  return fallback;
}

String _initials(String fullName) {
  final words = fullName
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return '?';
  }
  if (words.length == 1) {
    return words.first[0].toUpperCase();
  }
  return '${words[0][0]}${words[1][0]}'.toUpperCase();
}

String? _firstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = _valueAsString(data[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _valueAsString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

bool _isPermissionGranted(AuthorizationStatus status) {
  return status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}

String _statusLabel(
  S l10n,
  AuthorizationStatus? status,
  NotificationClientPlatform platform,
) {
  switch (status) {
    case AuthorizationStatus.authorized:
      return l10n.notificationsEnabledForPlatform(platform.displayName);
    case AuthorizationStatus.provisional:
      return l10n.notificationsProvisionallyEnabled;
    case AuthorizationStatus.denied:
      return l10n.notificationsBlockedForPlatform(platform.displayName);
    case AuthorizationStatus.notDetermined:
    case null:
      return l10n.allowNotificationsPrompt;
  }
}

String _disableNotificationInstructions(
  S l10n,
  NotificationClientPlatform platform,
) {
  if (platform.isWeb && platform.isWindows) {
    return l10n.disableNotificationsWindows;
  }

  if (platform.isWeb && platform.isMacOS) {
    return l10n.disableNotificationsMac;
  }

  if (platform.isWeb) {
    return l10n.disableNotificationsWeb;
  }

  return l10n.disableNotificationsDevice;
}

String _blockedNotificationInstructions(
  S l10n,
  NotificationClientPlatform platform,
) {
  if (platform.isWeb && platform.isWindows) {
    return l10n.blockedNotificationsWindows;
  }

  if (platform.isWeb && platform.isMacOS) {
    return l10n.blockedNotificationsMac;
  }

  if (platform.isWeb) {
    return l10n.blockedNotificationsWeb;
  }

  return l10n.blockedNotificationsDevice;
}

String _stringifyValue(dynamic value) {
  if (value == null) {
    return '-';
  }

  if (value is String) {
    return value.isEmpty ? '-' : value;
  }

  if (value is bool || value is num) {
    return value.toString();
  }

  if (value is List) {
    if (value.isEmpty) {
      return '-';
    }
    return value.map(_stringifyValue).join(', ');
  }

  if (value is Map) {
    if (value.isEmpty) {
      return '-';
    }
    return jsonEncode(value);
  }

  return value.toString();
}
