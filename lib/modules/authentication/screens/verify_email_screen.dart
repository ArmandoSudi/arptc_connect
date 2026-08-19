import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
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
                      Icons.mark_email_unread_outlined,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.verifyEmailTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.verifyEmailDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isWorking ? null : _checkVerification,
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(l10n.checkVerificationStatus),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isWorking ? null : _resendVerification,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(l10n.resendVerificationEmail),
                    ),
                    TextButton.icon(
                      onPressed: _isWorking ? null : _signOut,
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

  Future<void> _checkVerification() async {
    await _perform(() async {
      await ref.read(authServiceProvider).reloadCurrentUser();
      ref.invalidate(authStateProvider);
    });
  }

  Future<void> _resendVerification() async {
    await _perform(() async {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).verificationEmailSent)),
      );
    });
  }

  Future<void> _signOut() async {
    await _perform(() => ref.read(authServiceProvider).signOut());
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() => _isWorking = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).unableToCompleteAction)),
      );
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }
}
