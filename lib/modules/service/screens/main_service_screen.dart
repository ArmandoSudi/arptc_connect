import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/service/module_config.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/module_card.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainServiceScreen extends ConsumerWidget {
  const MainServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final sessionState = ref.watch(authorizedSessionProvider);
    final profile = sessionState.session == null
        ? null
        : Map<String, dynamic>.from(sessionState.session!.profile);
    final modulesAsync = ref.watch(umModulesProvider);
    final configuredModules =
        modulesAsync.valueOrNull ?? const <UserManagementModule>[];
    final agentDisplayName = profile == null
        ? l10n.agent
        : _buildAgentDisplayName(profile, fallback: l10n.agent);
    final permittedModules = profile == null
        ? const <ModuleInfo>[]
        : _resolvePermittedModules(
            profile,
            configuredModules: configuredModules,
          );
    final loadingPermissions =
        (sessionState.status == AuthenticationStatus.initializing ||
                sessionState.status == AuthenticationStatus.profileLoading ||
                modulesAsync.isLoading) &&
            permittedModules.isEmpty;

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
                  l10n.serviceWelcome,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LoadingStateView(message: l10n.loadingModules),
            ),
          )
        else if (permittedModules.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyStateView(
                icon: Icons.lock_outline,
                title: l10n.noAuthorizedModule,
                description: l10n.noAuthorizedModuleDescription,
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
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = permittedModules[index];
                  return ModuleCard(
                    module: _localizedModuleInfo(context, module),
                  );
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
    if (width > 1200) return 5;
    if (width > 800) return 4;
    if (width > 600) return 2;
    return 2;
  }
}

String _buildAgentDisplayName(
  Map<String, dynamic> data, {
  required String fallback,
}) {
  final pieces = [
    (data['firstName'] ?? '').toString().trim(),
    (data['name'] ?? '').toString().trim(),
    (data['postName'] ?? '').toString().trim(),
  ].where((piece) => piece.isNotEmpty).toList();

  if (pieces.isNotEmpty) {
    return pieces.join(' ');
  }

  final emailFallback =
      (data['email'] ?? data['emailLower'] ?? '').toString().trim();
  if (emailFallback.isNotEmpty) {
    return emailFallback;
  }

  return fallback;
}

ModuleInfo _localizedModuleInfo(BuildContext context, ModuleInfo moduleInfo) {
  if (!_usesStaticModuleText(moduleInfo)) {
    return moduleInfo;
  }

  final l10n = S.of(context);

  switch (moduleInfo.module) {
    case AppModule.tasks:
      return _withLocalizedModuleText(
        moduleInfo,
        name: l10n.moduleTasksName,
        description: l10n.moduleTasksDescription,
      );
    case AppModule.courriers:
      return _withLocalizedModuleText(
        moduleInfo,
        name: l10n.moduleCourrierName,
        description: l10n.moduleCourrierDescription,
      );
    case AppModule.news:
      return _withLocalizedModuleText(
        moduleInfo,
        name: l10n.moduleNewsName,
        description: l10n.moduleNewsDescription,
      );
    case AppModule.inventory:
      return _withLocalizedModuleText(
        moduleInfo,
        name: l10n.moduleInventoryName,
        description: l10n.moduleInventoryDescription,
      );
    case AppModule.itsm:
      return _withLocalizedModuleText(
        moduleInfo,
        name: l10n.moduleItsmName,
        description: l10n.moduleItsmDescription,
      );
    case AppModule.usermanagement:
      return _withLocalizedModuleText(
        moduleInfo,
        name: l10n.moduleUserManagementName,
        description: l10n.moduleUserManagementDescription,
      );
    case AppModule.social:
    case AppModule.meetinghall:
      return moduleInfo;
  }
}

bool _usesStaticModuleText(ModuleInfo moduleInfo) {
  for (final staticModule in ModulesConfig.allModules) {
    if (staticModule.module == moduleInfo.module) {
      return moduleInfo.name == staticModule.name &&
          moduleInfo.description == staticModule.description;
    }
  }
  return false;
}

ModuleInfo _withLocalizedModuleText(
  ModuleInfo moduleInfo, {
  required String name,
  required String description,
}) {
  return ModuleInfo(
    module: moduleInfo.module,
    name: name,
    description: description,
    icon: moduleInfo.icon,
    color: moduleInfo.color,
  );
}

List<ModuleInfo> _resolvePermittedModules(
  Map<String, dynamic> profile, {
  required List<UserManagementModule> configuredModules,
}) {
  final rawPermissions = _asPermissionMap(profile['modulePermissions']);
  final normalizedPermissions = Modules.normalizePermissions(
    rawPermissions,
    includeDefaultModules: false,
  );
  final availableModules = _resolveAvailableModules(configuredModules);

  return availableModules.where((moduleInfo) {
    final canonicalKey =
        Modules.normalizeModuleKey(moduleInfo.module.permissionKey);
    final permissionValue =
        normalizedPermissions[canonicalKey] ?? ModuleAccessRole.none.value;
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

List<ModuleInfo> _resolveAvailableModules(
  List<UserManagementModule> configuredModules,
) {
  final configuredByKey = <String, UserManagementModule>{};
  for (final configured in configuredModules) {
    final key = Modules.normalizeModuleKey(configured.key);
    if (key.isNotEmpty) {
      configuredByKey[key] = configured;
    }
  }

  final modules = <ModuleInfo>[];
  for (final staticModule in ModulesConfig.allModules) {
    final key = Modules.normalizeModuleKey(staticModule.module.permissionKey);
    final configured = configuredByKey[key];
    if (configured != null && !configured.isActive) {
      continue;
    }
    modules.add(
      configured == null
          ? staticModule
          : _applyConfiguredModuleMetadata(staticModule, configured),
    );
  }

  return modules;
}

ModuleInfo _applyConfiguredModuleMetadata(
  ModuleInfo base,
  UserManagementModule configured,
) {
  // ITSM is the product-facing replacement for the legacy Incident module.
  // Keep Firestore activation and permission data, but do not allow stale
  // configured labels to restore the old card.
  if (base.module == AppModule.itsm) {
    return base;
  }
  return ModuleInfo(
    module: base.module,
    name: configured.name.trim().isEmpty ? base.name : configured.name.trim(),
    description: configured.description.trim().isEmpty
        ? base.description
        : configured.description.trim(),
    icon: base.icon,
    color: base.color,
  );
}
