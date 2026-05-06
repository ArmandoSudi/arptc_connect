import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:arptc_connect/modules/service/module_config.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/widgets/module_card.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainServiceScreen extends ConsumerWidget {
  const MainServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(liveAgentProfileProvider);
    final agentDisplayName = profileAsync.maybeWhen(
      data: _buildAgentDisplayName,
      orElse: () => 'Agent',
    );
    final permittedModules = profileAsync.maybeWhen(
      data: _resolvePermittedModules,
      orElse: () => const <ModuleInfo>[],
    );
    final loadingPermissions = profileAsync.isLoading;

    return CustomScrollView(
      slivers: [
        // Welcome Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  agentDisplayName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),
        ),

        if (loadingPermissions)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: LoadingStateView(message: 'Loading modules...'),
            ),
          )
        else if (permittedModules.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyStateView(
                icon: Icons.lock_outline,
                title: 'No authorized module',
                description:
                    'No module is assigned to this agent. Please contact an administrator.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = permittedModules[index];
                  return ModuleCard(module: module);
                },
                childCount: permittedModules.length,
              ),
            ),
          ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }
}

String _buildAgentDisplayName(Map<String, dynamic> data) {
  final pieces = [
    (data['firstName'] ?? '').toString().trim(),
    (data['name'] ?? '').toString().trim(),
    (data['postName'] ?? '').toString().trim(),
  ].where((piece) => piece.isNotEmpty).toList();

  if (pieces.isNotEmpty) {
    return pieces.join(' ');
  }

  final fallback =
      (data['email'] ?? data['emailLower'] ?? '').toString().trim();
  if (fallback.isNotEmpty) {
    return fallback;
  }

  return 'Agent';
}

List<ModuleInfo> _resolvePermittedModules(Map<String, dynamic> profile) {
  final rawPermissions = _asPermissionMap(profile['modulePermissions']);
  final normalizedPermissions = Modules.normalizePermissions(
    rawPermissions,
    includeDefaultModules: false,
  );

  return ModulesConfig.allModules.where((moduleInfo) {
    final permissionValue = _resolvePermissionValueForModule(
      module: moduleInfo.module,
      normalizedPermissions: normalizedPermissions,
      rawPermissions: rawPermissions,
    );
    return ModuleAccessRole.fromValue(permissionValue) != ModuleAccessRole.none;
  }).toList();
}

Map<String, dynamic>? _asPermissionMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  if (raw is List) {
    final mapped = <String, dynamic>{};
    for (final entry in raw) {
      if (entry is! Map) {
        continue;
      }
      final value = Map<String, dynamic>.from(entry);
      final key = (value['moduleKey'] ??
              value['key'] ??
              value['module'] ??
              value['moduleName'])
          ?.toString()
          .trim();
      if (key == null || key.isEmpty) {
        continue;
      }
      mapped[key] = value['role'] ?? value['permission'] ?? value['access'];
    }
    if (mapped.isNotEmpty) {
      return mapped;
    }
  }
  return null;
}

String _resolvePermissionValueForModule({
  required AppModule module,
  required Map<String, String> normalizedPermissions,
  required Map<String, dynamic>? rawPermissions,
}) {
  final candidates = _permissionKeyCandidates(module);

  for (final candidate in candidates) {
    final normalizedKey = Modules.normalizeModuleKey(candidate);
    final normalizedValue = normalizedPermissions[normalizedKey];
    if (normalizedValue != null) {
      return normalizedValue;
    }

    final rawValue = rawPermissions?[candidate];
    if (rawValue != null) {
      return ModuleAccessRole.fromDynamic(rawValue).value;
    }
  }

  return ModuleAccessRole.none.value;
}

List<String> _permissionKeyCandidates(AppModule module) {
  switch (module) {
    case AppModule.courriers:
      return const ['courriers', 'courrier', 'mail', 'mails'];
    case AppModule.ticketing:
      return const ['ticketing', 'ticket', 'tickets'];
    case AppModule.meetinghall:
      return const ['meetinghall', 'meeting_hall', 'meeting'];
    default:
      return [module.permissionKey];
  }
}
