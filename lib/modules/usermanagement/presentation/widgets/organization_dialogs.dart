import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

class OrganizationFormResult {
  const OrganizationFormResult({
    required this.code,
    required this.name,
    required this.description,
    required this.status,
  });

  final String code;
  final String name;
  final String description;
  final OrganizationStatus status;
}

Future<OrganizationFormResult?> showOrganizationFormDialog(
  BuildContext context, {
  Organization? organization,
  Future<void> Function(OrganizationFormResult result)? onSubmit,
  String Function(Object error)? submissionErrorBuilder,
  void Function(Object error, StackTrace stackTrace)? onSubmissionError,
}) {
  return showDialog<OrganizationFormResult>(
    context: context,
    barrierDismissible: onSubmit == null,
    builder: (_) => _OrganizationFormDialog(
      organization: organization,
      onSubmit: onSubmit,
      submissionErrorBuilder: submissionErrorBuilder,
      onSubmissionError: onSubmissionError,
    ),
  );
}

Future<String?> showOrganizationReasonDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String reasonLabel,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      description: description,
      reasonLabel: reasonLabel,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}

class _OrganizationFormDialog extends StatefulWidget {
  const _OrganizationFormDialog({
    this.organization,
    this.onSubmit,
    this.submissionErrorBuilder,
    this.onSubmissionError,
  });

  final Organization? organization;
  final Future<void> Function(OrganizationFormResult result)? onSubmit;
  final String Function(Object error)? submissionErrorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onSubmissionError;

  @override
  State<_OrganizationFormDialog> createState() =>
      _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends State<_OrganizationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late OrganizationStatus _status;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.organization?.code ?? '');
    _name = TextEditingController(text: widget.organization?.name ?? '');
    _description =
        TextEditingController(text: widget.organization?.description ?? '');
    _status = widget.organization?.status ?? OrganizationStatus.active;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup(
        widget.organization == null
            ? 'umCreateOrganization'
            : 'umEditOrganization',
      )),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonTextInput(
                  label: l10n.lookup('umOrganizationCode'),
                  controller: _code,
                  validator: _required(l10n),
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  label: l10n.lookup('umOrganizationName'),
                  type: CommonTextInputType.name,
                  controller: _name,
                  validator: _required(l10n),
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  label: l10n.lookup('umOrganizationDescription'),
                  controller: _description,
                  isMultiline: true,
                ),
                if (widget.organization != null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<OrganizationStatus>(
                    value: _status,
                    decoration: InputDecoration(labelText: l10n.status),
                    items: [
                      DropdownMenuItem(
                        value: OrganizationStatus.active,
                        child: Text(l10n.lookup('umActive')),
                      ),
                      DropdownMenuItem(
                        value: OrganizationStatus.inactive,
                        child: Text(l10n.lookup('umInactive')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                ],
                if (_submissionError != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _submissionError!,
                        key: const Key('organization-form-submission-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? SizedBox.square(
                  key: const Key('organization-form-progress'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(widget.organization == null ? l10n.create : l10n.save),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = OrganizationFormResult(
      code: _code.text.trim(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      status: _status,
    );
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      Navigator.pop(context, result);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      await onSubmit(result);
      if (mounted) Navigator.pop(context, result);
    } catch (error, stackTrace) {
      widget.onSubmissionError?.call(error, stackTrace);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionError =
            widget.submissionErrorBuilder?.call(error) ?? error.toString();
      });
    }
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.description,
    required this.reasonLabel,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String description;
  final String reasonLabel;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.description),
              const SizedBox(height: 20),
              CommonTextInput(
                label: widget.reasonLabel,
                controller: _reason,
                isMultiline: true,
                validator: _required(l10n),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _reason.text.trim());
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

String? Function(String?) _required(S l10n) =>
    (value) => value == null || value.trim().isEmpty
        ? l10n.lookup('umRequiredField')
        : null;
