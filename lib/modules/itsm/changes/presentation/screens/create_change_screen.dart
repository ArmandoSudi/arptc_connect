import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/changes_application.dart';
import '../../domain/changes_domain.dart';
import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../change_presentation_strings.dart';
import '../widgets/change_page_shell.dart';

class CreateChangeScreen extends ConsumerStatefulWidget {
  const CreateChangeScreen({
    required this.onCreated,
    super.key,
    this.onBack,
    this.workflowDefinitionIds = const {
      ChangeType.standard: 'change-standard',
      ChangeType.normal: 'change-normal',
      ChangeType.emergency: 'change-emergency',
    },
  });

  final ValueChanged<String> onCreated;
  final VoidCallback? onBack;
  final Map<ChangeType, String> workflowDefinitionIds;

  @override
  ConsumerState<CreateChangeScreen> createState() => _CreateChangeScreenState();
}

class _CreateChangeScreenState extends ConsumerState<CreateChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _justification = TextEditingController();
  ChangeType _type = ChangeType.normal;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _justification.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return ChangePageShell(
      title: l10n.newChange,
      subtitle: l10n.changeManagementSubtitle,
      onBack: widget.onBack,
      child: ChangeSurfaceCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ChangeType>(
                value: _type,
                decoration: InputDecoration(labelText: l10n.changeType),
                items: [
                  for (final type in ChangeType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(l10n.changeTypeLabel(type)),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 16),
              CommonTextInput(
                label: l10n.title,
                controller: _title,
                validator: _required,
              ),
              const SizedBox(height: 16),
              CommonTextInput(
                label: l10n.description,
                controller: _description,
                isMultiline: true,
                validator: _required,
              ),
              const SizedBox(height: 16),
              CommonTextInput(
                label: l10n.changeJustification,
                controller: _justification,
                isMultiline: true,
                validator: _required,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _saveDraft,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.saveChangeDraft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value?.trim().isEmpty ?? true ? S.of(context).requiredField : null;

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final controller = await ref.read(changeCommandControllerProvider.future);
      final nonce = DateTime.now().microsecondsSinceEpoch;
      final changeId = 'change_${session.userId}_$nonce'
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      await controller.execute(
        ChangeCommand(
          context: ItsmCommandContext(
            idempotencyKey: 'change-draft-$changeId',
            correlationId: changeId,
            actorUserId: session.userId,
            actorRole: session.role,
            actorDisplayName: session.displayName,
          ),
          type: ChangeCommandType.initializeDraft,
          payload: {
            'changeId': changeId,
            'workflowDefinitionId': widget.workflowDefinitionIds[_type]!,
            'changeType': _type.value,
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'justification': _justification.text.trim(),
          },
        ),
      );
      if (mounted) widget.onCreated(changeId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
