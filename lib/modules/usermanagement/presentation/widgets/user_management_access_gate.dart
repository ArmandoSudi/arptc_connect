import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserManagementAccessGate extends ConsumerWidget {
  const UserManagementAccessGate({
    required this.child,
    this.requirePrivateProfiles = false,
    super.key,
  });

  final Widget child;
  final bool requirePrivateProfiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authorizedAgentProfileProvider);
    final policy = ref.watch(userManagementAccessPolicyProvider);
    if (profile.isLoading) {
      return LoadingStateView(message: S.of(context).lookup('umLoading'));
    }
    if (profile.hasError ||
        !policy.canOpenModule ||
        (requirePrivateProfiles && !policy.canReadPrivateProfiles)) {
      return ErrorStateView(title: S.of(context).lookup('umAccessDenied'));
    }
    return child;
  }
}
