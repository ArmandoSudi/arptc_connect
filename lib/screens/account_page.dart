import 'package:arptc_connect/core/theme_provider.dart';
import 'package:arptc_connect/modules/administration/domain/models/dependant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/authentication/providers/authentication_provider.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final db = FirebaseFirestore.instance;

  CollectionReference dependants = FirebaseFirestore.instance
      .collection('/agents/PyKV8iGiDzcTdQSaRzWD/dependants');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        actions: [
          // Theme mode toggle button
          IconButton(
            onPressed: () => _showThemeBottomSheet(context, ref),
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
            ),
            tooltip: 'Change theme',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24, width: double.infinity),

                // Profile Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 56,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "John Doe",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "john.doe@arptc.gouv.cd",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  "08888888888888",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                // Administration Section
                const _SectionHeader(title: "Administration"),
                const SizedBox(height: 8),

                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          label: "Direction",
                          value: "Direction des systèmes d'information",
                        ),
                        SizedBox(height: 12),
                        _InfoRow(
                          label: "Service",
                          value:
                              "Service de devéloppement des applications et gestion de la base des données",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Social Section
                const _SectionHeader(title: "Social"),
                const SizedBox(height: 8),
                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dependants",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                            stream: dependants.snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  "Something went wrong",
                                  style: TextStyle(color: colorScheme.error),
                                );
                              }

                              if (snapshot.data == null ||
                                  snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                );
                              } else if (!snapshot.hasData) {
                                return Text(
                                  "There is no dependant yet",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }
                              return _buildDependantList(
                                  context, snapshot.data?.docs ?? []);
                            })
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign out button
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    ref.read(authServiceProvider).signOut();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text("Sign Out"),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Version : 0.0.1",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System'),
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDependantList(
      BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: snapshot.map((data) => _buildDepandant(context, data)).toList(),
    );
  }

  Widget _buildDepandant(BuildContext context, DocumentSnapshot data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const dependant = Dependant(
      name: "John Doe, Jr",
      relationship: "Fils",
      imageURL: "www.google.com",
      id: "123456",
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(
          Icons.person,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(dependant.name),
      subtitle: Text(
        dependant.relationship,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      onTap: () {
        debugPrint("Doc ID: ${dependant.id}");
      },
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Info row widget for displaying label-value pairs
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
