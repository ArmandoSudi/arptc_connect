import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/social/screens/social_agent_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialAgentsPage extends ConsumerStatefulWidget {
  const SocialAgentsPage({super.key});

  @override
  ConsumerState<SocialAgentsPage> createState() => _SocialAgentsPageState();
}

class _SocialAgentsPageState extends ConsumerState<SocialAgentsPage> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final directory = ref.watch(umCurrentOrganizationAgentDirectoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lookup('umAgents'))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: CommonTextInput(
                label: l10n.lookup('umSearchAgents'),
                controller: _searchController,
                prefixIcon: const Icon(Icons.search),
                onChanged: (value) => setState(() {
                  _search = value.trim().toLowerCase();
                }),
              ),
            ),
            Expanded(
              child: directory.when(
                loading: () =>
                    LoadingStateView(message: l10n.lookup('umLoading')),
                error: (error, _) => ErrorStateView(
                  title: l10n.lookup('umCommandFailed'),
                  description: error.toString(),
                ),
                data: (entries) {
                  final visible = entries
                      .where((entry) =>
                          _search.isEmpty ||
                          entry.displayNameLower.contains(_search))
                      .toList(growable: false);
                  if (visible.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.person_search_outlined,
                      title: l10n.lookup('umNoAgents'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _DirectoryTile(entry: visible[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryTile extends StatelessWidget {
  const _DirectoryTile({required this.entry});

  final AgentDirectoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final image = entry.profilePictureUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: image == null ? null : NetworkImage(image),
          child: image == null ? Text(_initials(entry.displayName)) : null,
        ),
        title: Text(
          entry.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [entry.jobTitle, entry.organizationBreadcrumb]
              .where((value) => value.isNotEmpty)
              .join('\n'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SocialAgentDetailsScreen(agent: entry),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) => name
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();
