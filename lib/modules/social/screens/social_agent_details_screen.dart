import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:flutter/material.dart';

class SocialAgentDetailsScreen extends StatelessWidget {
  const SocialAgentDetailsScreen({required this.agent, super.key});

  final AgentDirectoryEntry agent;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final image = agent.profilePictureUrl;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lookup('umAgentDetails'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              child: CircleAvatar(
                radius: 48,
                backgroundImage: image == null ? null : NetworkImage(image),
                child: image == null
                    ? Text(
                        _initials(agent.displayName),
                        style: Theme.of(context).textTheme.headlineSmall,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              agent.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _DetailRow(label: l10n.email, value: agent.email),
                    _DetailRow(
                      label: l10n.lookup('umJobTitle'),
                      value: agent.jobTitle,
                    ),
                    _DetailRow(
                      label: l10n.lookup('umOrganizationPath'),
                      value: agent.organizationBreadcrumb,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value.isEmpty ? '-' : value),
    );
  }
}

String _initials(String name) => name
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();
