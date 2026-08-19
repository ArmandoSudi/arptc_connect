import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InitialPasswordChangeScreen extends ConsumerStatefulWidget {
  const InitialPasswordChangeScreen({super.key});

  @override
  ConsumerState<InitialPasswordChangeScreen> createState() =>
      _InitialPasswordChangeScreenState();
}

class _InitialPasswordChangeScreenState
    extends ConsumerState<InitialPasswordChangeScreen> {
  static const _temporaryPassword = 'Arptc@1234';

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.password_rounded,
                        size: 54,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.lookup('initialPasswordChangeTitle'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.lookup('initialPasswordChangeDescription'),
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      CommonTextInput(
                        label: l10n.lookup('newPassword'),
                        controller: _passwordController,
                        isPassword: true,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearSubmissionError(),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 18),
                      CommonTextInput(
                        label: l10n.lookup('confirmNewPassword'),
                        controller: _confirmationController,
                        isPassword: true,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _clearSubmissionError(),
                        onSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return l10n.lookup('passwordsDoNotMatch');
                          }
                          return null;
                        },
                      ),
                      if (_submissionError != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          key: const Key('initial-password-error'),
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _submissionError!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('initial-password-submit'),
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            l10n.lookup('saveNewPassword'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : _signOut,
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
      ),
    );
  }

  String? _validatePassword(String? value) {
    final l10n = S.of(context);
    if (value == null || value.length < 8) {
      return l10n.lookup('newPasswordMinimumLength');
    }
    if (value == _temporaryPassword) {
      return l10n.lookup('newPasswordMustDiffer');
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }
    final fallbackError = S.of(context).unableToCompleteAction;
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      await ref.read(authServiceProvider).completeInitialPasswordChange(
            _passwordController.text,
          );
    } on FirebaseFunctionsException catch (error) {
      _showError(error.message ?? fallbackError);
    } catch (_) {
      _showError(fallbackError);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _submissionError = message);
  }

  void _clearSubmissionError() {
    if (_submissionError == null || !mounted) return;
    setState(() => _submissionError = null);
  }
}
