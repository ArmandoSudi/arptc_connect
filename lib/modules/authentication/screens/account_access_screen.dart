import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountAccessScreen extends ConsumerWidget {
  const AccountAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final state = ref.watch(authorizedSessionProvider);
    final description = state.status == AuthenticationStatus.accountDisabled
        ? l10n.accountAccessDisabled
        : l10n.accountAccessProfileMissing;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 52,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.accountAccessTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        ref.invalidate(liveAgentProfileProvider);
                        ref.invalidate(authorizedSessionProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.accountAccessRetry),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.signOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
