import 'dart:convert';

import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(cachedAgentProfileProvider);
    final theme = Theme.of(context);

    return ContentView(
      child: profileAsync.when(
        data: (profile) {
          if (profile.isEmpty) {
            return ErrorStateView(
              title: 'Profile unavailable',
              description:
                  'No agent data is cached on this device for the current session.',
              onRetry: () => ref.invalidate(cachedAgentProfileProvider),
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
          final fullName = _buildDisplayName(profile);
          final email = _valueAsString(profile['email']);
          final entries = _buildFieldEntries(profile);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: 'Profile',
                  description: 'Connected agent information',
                ),
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
                                email.isEmpty ? 'No email' : email,
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
                          'Agent Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (entries.isEmpty)
                          const EmptyStateView(
                            icon: Icons.info_outline,
                            title: 'No fields',
                            description: 'No profile fields available.',
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
                        text: 'Refresh Profile',
                        onPressed: () {
                          ref.invalidate(cachedAgentProfileProvider);
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
                        label: const Text('Sign Out'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        error: (error, _) => ErrorStateView(
          title: 'Unable to load profile',
          description: error.toString(),
          onRetry: () => ref.invalidate(cachedAgentProfileProvider),
        ),
        loading: () => const LoadingStateView(message: 'Loading profile...'),
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
    Map<String, dynamic> profile) {
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
    entries.add(MapEntry(_prettyLabel(key), _stringifyValue(profile[key])));
  }

  final extraKeys =
      profile.keys.where((key) => !consumedKeys.contains(key)).toList()..sort();

  for (final key in extraKeys) {
    entries.add(MapEntry(_prettyLabel(key), _stringifyValue(profile[key])));
  }

  return entries;
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

String _buildDisplayName(Map<String, dynamic> data) {
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

  return 'Agent';
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
