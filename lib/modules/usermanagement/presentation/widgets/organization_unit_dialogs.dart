import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

class OrganizationUnitFormResult {
  const OrganizationUnitFormResult({
    required this.type,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
  });

  final OrganizationUnitType type;
  final String code;
  final String name;
  final String description;
  final OrganizationStatus status;
}

class OrganizationHeadFormResult {
  const OrganizationHeadFormResult({
    required this.agentId,
    required this.isActing,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
  });

  final String agentId;
  final bool isActing;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String reason;
}

class OrganizationUnitMoveResult {
  const OrganizationUnitMoveResult({
    required this.parentUnitId,
    required this.reason,
  });

  final String parentUnitId;
  final String reason;
}

Future<OrganizationUnitFormResult?> showOrganizationUnitFormDialog(
  BuildContext context, {
  required OrganizationUnitType type,
  OrganizationUnit? unit,
  Future<void> Function(OrganizationUnitFormResult result)? onSubmit,
  String Function(Object error)? submissionErrorBuilder,
  void Function(Object error, StackTrace stackTrace)? onSubmissionError,
}) {
  return showDialog<OrganizationUnitFormResult>(
    context: context,
    barrierDismissible: onSubmit == null,
    builder: (_) => _OrganizationUnitFormDialog(
      type: type,
      unit: unit,
      onSubmit: onSubmit,
      submissionErrorBuilder: submissionErrorBuilder,
      onSubmissionError: onSubmissionError,
    ),
  );
}

Future<OrganizationHeadFormResult?> showOrganizationHeadDialog(
  BuildContext context, {
  required List<AgentDirectoryEntry> agents,
  bool allowPermanent = true,
  bool allowActing = true,
  Future<void> Function(OrganizationHeadFormResult result)? onSubmit,
  String Function(Object error)? submissionErrorBuilder,
  void Function(Object error, StackTrace stackTrace)? onSubmissionError,
}) {
  return showDialog<OrganizationHeadFormResult>(
    context: context,
    barrierDismissible: onSubmit == null,
    builder: (_) => _OrganizationHeadDialog(
      agents: agents,
      allowPermanent: allowPermanent,
      allowActing: allowActing,
      onSubmit: onSubmit,
      submissionErrorBuilder: submissionErrorBuilder,
      onSubmissionError: onSubmissionError,
    ),
  );
}

Future<OrganizationUnitMoveResult?> showOrganizationUnitMoveDialog(
  BuildContext context, {
  required OrganizationUnit unit,
  required List<OrganizationUnit> eligibleParents,
}) {
  return showDialog<OrganizationUnitMoveResult>(
    context: context,
    builder: (_) => _OrganizationUnitMoveDialog(
      unit: unit,
      eligibleParents: eligibleParents,
    ),
  );
}

class _OrganizationUnitFormDialog extends StatefulWidget {
  const _OrganizationUnitFormDialog({
    required this.type,
    this.unit,
    this.onSubmit,
    this.submissionErrorBuilder,
    this.onSubmissionError,
  });

  final OrganizationUnitType type;
  final OrganizationUnit? unit;
  final Future<void> Function(OrganizationUnitFormResult result)? onSubmit;
  final String Function(Object error)? submissionErrorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onSubmissionError;

  @override
  State<_OrganizationUnitFormDialog> createState() =>
      _OrganizationUnitFormDialogState();
}

class _OrganizationUnitFormDialogState
    extends State<_OrganizationUnitFormDialog> {
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
    _code = TextEditingController(text: widget.unit?.code ?? '');
    _name = TextEditingController(text: widget.unit?.name ?? '');
    _description = TextEditingController(text: widget.unit?.description ?? '');
    _status = widget.unit?.status ?? OrganizationStatus.active;
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
        widget.unit == null ? 'umCreateChildUnit' : 'umEditUnit',
      )),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_unitIcon(widget.type)),
                  title: Text(_unitTypeLabel(l10n, widget.type)),
                  subtitle: Text(l10n.lookup('umUnitType')),
                ),
                CommonTextInput(
                  label: l10n.lookup('umUnitCode'),
                  controller: _code,
                  validator: _required(l10n),
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  label: l10n.lookup('umUnitName'),
                  controller: _name,
                  type: CommonTextInputType.name,
                  validator: _required(l10n),
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  label: l10n.lookup('umOrganizationDescription'),
                  controller: _description,
                  isMultiline: true,
                ),
                if (widget.unit != null) ...[
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
                      key: const Key('organization-unit-form-submission-error'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _submissionError!,
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
                  key: const Key('organization-unit-form-progress'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(widget.unit == null ? l10n.create : l10n.save),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = OrganizationUnitFormResult(
      type: widget.type,
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

class _OrganizationHeadDialog extends StatefulWidget {
  const _OrganizationHeadDialog({
    required this.agents,
    required this.allowPermanent,
    required this.allowActing,
    this.onSubmit,
    this.submissionErrorBuilder,
    this.onSubmissionError,
  });

  final List<AgentDirectoryEntry> agents;
  final bool allowPermanent;
  final bool allowActing;
  final Future<void> Function(OrganizationHeadFormResult result)? onSubmit;
  final String Function(Object error)? submissionErrorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onSubmissionError;

  @override
  State<_OrganizationHeadDialog> createState() =>
      _OrganizationHeadDialogState();
}

class _OrganizationUnitMoveDialog extends StatefulWidget {
  const _OrganizationUnitMoveDialog({
    required this.unit,
    required this.eligibleParents,
  });

  final OrganizationUnit unit;
  final List<OrganizationUnit> eligibleParents;

  @override
  State<_OrganizationUnitMoveDialog> createState() =>
      _OrganizationUnitMoveDialogState();
}

class _OrganizationUnitMoveDialogState
    extends State<_OrganizationUnitMoveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _parentUnitId;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('umMoveUnit')),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.lookup('umMoveUnitDescription'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _parentUnitId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.lookup('umNewParentUnit'),
                    prefixIcon: const Icon(Icons.account_tree_outlined),
                  ),
                  items: widget.eligibleParents
                      .map(
                        (parent) => DropdownMenuItem(
                          value: parent.id,
                          child: Text(
                            parent.breadcrumb,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? l10n.lookup('umRequiredField') : null,
                  onChanged: (value) => setState(() => _parentUnitId = value),
                ),
                const SizedBox(height: 16),
                CommonTextInput(
                  label: l10n.lookup('umMoveReason'),
                  controller: _reason,
                  isMultiline: true,
                  validator: _required(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              OrganizationUnitMoveResult(
                parentUnitId: _parentUnitId!,
                reason: _reason.text.trim(),
              ),
            );
          },
          child: Text(l10n.lookup('umMoveUnit')),
        ),
      ],
    );
  }
}

class _OrganizationHeadDialogState extends State<_OrganizationHeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _agentId;
  bool _isActing = false;
  DateTime _startsAt = DateTime.now();
  DateTime? _endsAt;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _isActing = !widget.allowPermanent && widget.allowActing;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('umAssignHead')),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _agentId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.lookup('umSelectAgent'),
                  ),
                  items: widget.agents
                      .map((agent) => DropdownMenuItem(
                            value: agent.id,
                            child: Text(agent.displayName),
                          ))
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? l10n.lookup('umRequiredField') : null,
                  onChanged: (value) => setState(() => _agentId = value),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActing,
                  title: Text(l10n.lookup('umActingHead')),
                  subtitle: Text(l10n.lookup('umPermanentHead')),
                  onChanged: _isSubmitting ||
                          !widget.allowPermanent ||
                          !widget.allowActing
                      ? null
                      : (value) => setState(() {
                            _isActing = value;
                            if (!value) _endsAt = null;
                          }),
                ),
                _DateTile(
                  label: l10n.lookup('umAssignmentStartDate'),
                  value: _startsAt,
                  onSelected: (value) => setState(() => _startsAt = value),
                ),
                if (_isActing)
                  _DateTile(
                    label: l10n.lookup('umLeadershipEndDate'),
                    value: _endsAt,
                    onSelected: (value) => setState(() => _endsAt = value),
                  ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.lookup('umLeadershipReason'),
                  controller: _reason,
                  isMultiline: true,
                  validator: _required(l10n),
                ),
                if (_submissionError != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      key: const Key('organization-head-submission-error'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _submissionError!,
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
                  key: const Key('organization-head-progress'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = S.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_isActing && _endsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lookup('umLeadershipEndDate'))),
      );
      return;
    }
    final result = OrganizationHeadFormResult(
      agentId: _agentId!,
      isActing: _isActing,
      startsAt: _startsAt,
      endsAt: _endsAt,
      reason: _reason.text.trim(),
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      subtitle: Text(value == null
          ? '-'
          : '${value!.day.toString().padLeft(2, '0')}/'
              '${value!.month.toString().padLeft(2, '0')}/${value!.year}'),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (selected != null) onSelected(selected);
      },
    );
  }
}

String? Function(String?) _required(S l10n) =>
    (value) => value == null || value.trim().isEmpty
        ? l10n.lookup('umRequiredField')
        : null;

String _unitTypeLabel(S l10n, OrganizationUnitType type) => switch (type) {
      OrganizationUnitType.department => l10n.lookup('umDepartment'),
      OrganizationUnitType.service => l10n.lookup('umService'),
      OrganizationUnitType.bureau => l10n.lookup('umBureau'),
      OrganizationUnitType.custom => l10n.lookup('umUnitType'),
    };

IconData _unitIcon(OrganizationUnitType type) => switch (type) {
      OrganizationUnitType.department => Icons.apartment_outlined,
      OrganizationUnitType.service => Icons.hub_outlined,
      OrganizationUnitType.bureau => Icons.meeting_room_outlined,
      OrganizationUnitType.custom => Icons.account_tree_outlined,
    };
