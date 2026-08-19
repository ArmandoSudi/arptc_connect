import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/unplaced_agent_summary.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_unit_hierarchy_selector.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

class OrganizationAgentFormResult {
  const OrganizationAgentFormResult({
    required this.firstName,
    required this.name,
    required this.postName,
    required this.matricule,
    required this.sex,
    required this.email,
    required this.jobTitle,
    required this.unitId,
    required this.startsAt,
    required this.reason,
    required this.assignAsHead,
  });

  final String firstName;
  final String name;
  final String postName;
  final String matricule;
  final AgentSex sex;
  final String email;
  final String jobTitle;
  final String unitId;
  final DateTime startsAt;
  final String reason;
  final bool assignAsHead;
}

class OrganizationAgentEditResult {
  const OrganizationAgentEditResult({
    required this.firstName,
    required this.name,
    required this.postName,
    required this.matricule,
    required this.sex,
    required this.email,
    required this.jobTitle,
    required this.modulePermissions,
  });

  final String firstName;
  final String name;
  final String postName;
  final String matricule;
  final AgentSex sex;
  final String email;
  final String jobTitle;
  final Map<String, String> modulePermissions;
}

class OrganizationTransferFormResult {
  const OrganizationTransferFormResult({
    required this.unitId,
    required this.startsAt,
    required this.reason,
    required this.assignAsHead,
  });

  final String unitId;
  final DateTime startsAt;
  final String reason;
  final bool assignAsHead;
}

class ExistingAgentAssignmentFormResult {
  const ExistingAgentAssignmentFormResult({
    required this.agentId,
    required this.unitId,
    required this.startsAt,
    required this.reason,
  });

  final String agentId;
  final String unitId;
  final DateTime startsAt;
  final String reason;
}

Future<OrganizationAgentFormResult?> showCreateOrganizationAgentDialog(
  BuildContext context, {
  required List<OrganizationUnit> units,
  Future<void> Function(OrganizationAgentFormResult result)? onSubmit,
  String Function(Object error)? submissionErrorBuilder,
  void Function(Object error, StackTrace stackTrace)? onSubmissionError,
}) {
  return showDialog<OrganizationAgentFormResult>(
    context: context,
    barrierDismissible: onSubmit == null,
    builder: (_) => _CreateAgentDialog(
      units: units,
      onSubmit: onSubmit,
      submissionErrorBuilder: submissionErrorBuilder,
      onSubmissionError: onSubmissionError,
    ),
  );
}

Future<OrganizationAgentEditResult?> showEditOrganizationAgentDialog(
  BuildContext context, {
  required UserManagementAgent agent,
  Future<void> Function(OrganizationAgentEditResult result)? onSubmit,
  String Function(Object error)? submissionErrorBuilder,
  void Function(Object error, StackTrace stackTrace)? onSubmissionError,
}) {
  return showDialog<OrganizationAgentEditResult>(
    context: context,
    barrierDismissible: onSubmit == null,
    builder: (_) => _EditAgentDialog(
      agent: agent,
      onSubmit: onSubmit,
      submissionErrorBuilder: submissionErrorBuilder,
      onSubmissionError: onSubmissionError,
    ),
  );
}

Future<OrganizationTransferFormResult?> showTransferOrganizationAgentDialog(
  BuildContext context, {
  required List<OrganizationUnit> units,
  required String currentUnitId,
  Future<void> Function(OrganizationTransferFormResult result)? onSubmit,
  String Function(Object error)? submissionErrorBuilder,
  void Function(Object error, StackTrace stackTrace)? onSubmissionError,
}) {
  return showDialog<OrganizationTransferFormResult>(
    context: context,
    barrierDismissible: onSubmit == null,
    builder: (_) => _TransferAgentDialog(
      units: units,
      currentUnitId: currentUnitId,
      onSubmit: onSubmit,
      submissionErrorBuilder: submissionErrorBuilder,
      onSubmissionError: onSubmissionError,
    ),
  );
}

Future<ExistingAgentAssignmentFormResult?>
    showAssignExistingOrganizationAgentDialog(
  BuildContext context, {
  required List<UnplacedAgentSummary> agents,
  required List<OrganizationUnit> units,
}) {
  return showDialog<ExistingAgentAssignmentFormResult>(
    context: context,
    builder: (_) => _AssignExistingAgentDialog(
      agents: agents,
      units: units,
    ),
  );
}

Future<UnplacedAgentSummary?> showMigrateLegacyAgentDialog(
  BuildContext context, {
  required List<UnplacedAgentSummary> agents,
}) {
  final l10n = S.of(context);
  return showDialog<UnplacedAgentSummary>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.lookup('umMigrateLegacyAgent')),
      content: SizedBox(
        width: 520,
        height: 360,
        child: ListView.separated(
          itemCount: agents.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final agent = agents[index];
            return ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: Text(agent.displayName),
              subtitle: Text(agent.email),
              onTap: () => Navigator.pop(dialogContext, agent),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  );
}

class _CreateAgentDialog extends StatefulWidget {
  const _CreateAgentDialog({
    required this.units,
    this.onSubmit,
    this.submissionErrorBuilder,
    this.onSubmissionError,
  });

  final List<OrganizationUnit> units;
  final Future<void> Function(OrganizationAgentFormResult result)? onSubmit;
  final String Function(Object error)? submissionErrorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onSubmissionError;

  @override
  State<_CreateAgentDialog> createState() => _CreateAgentDialogState();
}

class _CreateAgentDialogState extends State<_CreateAgentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _name = TextEditingController();
  final _postName = TextEditingController();
  final _matricule = TextEditingController();
  final _email = TextEditingController();
  final _jobTitle = TextEditingController();
  final _reason = TextEditingController(text: 'Initial organization placement');
  AgentSex? _sex;
  OrganizationPlacementSelection _placement =
      const OrganizationPlacementSelection();
  DateTime _startsAt = DateTime.now();
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void dispose() {
    _firstName.dispose();
    _name.dispose();
    _postName.dispose();
    _matricule.dispose();
    _email.dispose();
    _jobTitle.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('umCreateAgent')),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ResponsiveFields(children: [
                  CommonTextInput(
                    label: l10n.firstName,
                    controller: _firstName,
                    type: CommonTextInputType.name,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.name,
                    controller: _name,
                    type: CommonTextInputType.name,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.postName,
                    controller: _postName,
                    type: CommonTextInputType.name,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.matricule,
                    controller: _matricule,
                    validator: _required(l10n),
                  ),
                  _AgentSexField(
                    value: _sex,
                    onChanged: (value) => setState(() => _sex = value),
                  ),
                  CommonTextInput(
                    label: l10n.email,
                    controller: _email,
                    type: CommonTextInputType.email,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.lookup('umJobTitle'),
                    controller: _jobTitle,
                    validator: _required(l10n),
                  ),
                ]),
                const SizedBox(height: 16),
                OrganizationUnitHierarchySelector(
                  units: widget.units,
                  enabled: !_isSubmitting,
                  onChanged: (value) => _placement = value,
                ),
                _DateTile(
                  label: l10n.lookup('umAssignmentStartDate'),
                  value: _startsAt,
                  onSelected: (date) => setState(() => _startsAt = date),
                ),
                CommonTextInput(
                  label: l10n.lookup('umAssignmentReason'),
                  controller: _reason,
                  isMultiline: true,
                  validator: _required(l10n),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.password_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l10n.lookup('umDefaultPasswordNotice')),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_submissionError != null) ...[
                  const SizedBox(height: 16),
                  _SubmissionError(
                    key: const Key('organization-agent-create-error'),
                    message: _submissionError!,
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
                  key: const Key('organization-agent-create-progress'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(l10n.create),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = OrganizationAgentFormResult(
      firstName: _firstName.text.trim(),
      name: _name.text.trim(),
      postName: _postName.text.trim(),
      matricule: _matricule.text.trim(),
      sex: _sex!,
      email: _email.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      unitId: _placement.selectedUnitId!,
      startsAt: _startsAt,
      reason: _reason.text.trim(),
      assignAsHead: _placement.assignAsHead,
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

class _EditAgentDialog extends StatefulWidget {
  const _EditAgentDialog({
    required this.agent,
    this.onSubmit,
    this.submissionErrorBuilder,
    this.onSubmissionError,
  });

  final UserManagementAgent agent;
  final Future<void> Function(OrganizationAgentEditResult result)? onSubmit;
  final String Function(Object error)? submissionErrorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onSubmissionError;

  @override
  State<_EditAgentDialog> createState() => _EditAgentDialogState();
}

class _EditAgentDialogState extends State<_EditAgentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _name;
  late final TextEditingController _postName;
  late final TextEditingController _matricule;
  late final TextEditingController _email;
  late final TextEditingController _jobTitle;
  late final Map<String, String> _permissions;
  AgentSex? _sex;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    final agent = widget.agent;
    _firstName = TextEditingController(text: agent.firstName);
    _name = TextEditingController(text: agent.name);
    _postName = TextEditingController(text: agent.postName);
    _matricule = TextEditingController(text: agent.matricule);
    _sex = agent.sex;
    _email = TextEditingController(text: agent.email);
    _jobTitle = TextEditingController(text: agent.jobTitle);
    _permissions = Modules.normalizePermissions(agent.modulePermissions);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _name.dispose();
    _postName.dispose();
    _matricule.dispose();
    _email.dispose();
    _jobTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.editAgent),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ResponsiveFields(children: [
                  CommonTextInput(
                    label: l10n.firstName,
                    controller: _firstName,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.name,
                    controller: _name,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.postName,
                    controller: _postName,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.matricule,
                    controller: _matricule,
                    validator: _required(l10n),
                  ),
                  _AgentSexField(
                    value: _sex,
                    onChanged: (value) => setState(() => _sex = value),
                  ),
                  CommonTextInput(
                    label: l10n.email,
                    controller: _email,
                    type: CommonTextInputType.email,
                    validator: _required(l10n),
                  ),
                  CommonTextInput(
                    label: l10n.lookup('umJobTitle'),
                    controller: _jobTitle,
                    validator: _required(l10n),
                  ),
                ]),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.permissions,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                ...Modules.all.map((module) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DropdownButtonFormField<String>(
                        value: _permissions[module.key] ?? 'NONE',
                        decoration: InputDecoration(labelText: module.name),
                        items: module.availableRoles
                            .map((role) => DropdownMenuItem(
                                  value: role.value,
                                  child: Text(role.label),
                                ))
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) _permissions[module.key] = value;
                        },
                      ),
                    )),
                if (_submissionError != null) ...[
                  const SizedBox(height: 16),
                  _SubmissionError(
                    key: const Key('organization-agent-edit-error'),
                    message: _submissionError!,
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
                  key: const Key('organization-agent-edit-progress'),
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
    if (!_formKey.currentState!.validate()) return;
    final result = OrganizationAgentEditResult(
      firstName: _firstName.text.trim(),
      name: _name.text.trim(),
      postName: _postName.text.trim(),
      matricule: _matricule.text.trim(),
      sex: _sex!,
      email: _email.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      modulePermissions: Map.unmodifiable(_permissions),
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

class _AgentSexField extends StatelessWidget {
  const _AgentSexField({required this.value, required this.onChanged});

  final AgentSex? value;
  final ValueChanged<AgentSex?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return DropdownButtonFormField<AgentSex>(
      key: const Key('organization-agent-sex-dropdown'),
      value: value,
      decoration: InputDecoration(labelText: l10n.lookup('umSex')),
      items: AgentSex.values
          .map(
            (sex) => DropdownMenuItem(
              value: sex,
              child: Text(_agentSexLabel(l10n, sex)),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
      validator: (selected) =>
          selected == null ? l10n.lookup('umRequiredField') : null,
    );
  }
}

String _agentSexLabel(S l10n, AgentSex sex) {
  return switch (sex) {
    AgentSex.male => l10n.lookup('umMale'),
    AgentSex.female => l10n.lookup('umFemale'),
  };
}

class _SubmissionError extends StatelessWidget {
  const _SubmissionError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}

class _TransferAgentDialog extends StatefulWidget {
  const _TransferAgentDialog({
    required this.units,
    required this.currentUnitId,
    this.onSubmit,
    this.submissionErrorBuilder,
    this.onSubmissionError,
  });

  final List<OrganizationUnit> units;
  final String currentUnitId;
  final Future<void> Function(OrganizationTransferFormResult result)? onSubmit;
  final String Function(Object error)? submissionErrorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onSubmissionError;

  @override
  State<_TransferAgentDialog> createState() => _TransferAgentDialogState();
}

class _AssignExistingAgentDialog extends StatefulWidget {
  const _AssignExistingAgentDialog({
    required this.agents,
    required this.units,
  });

  final List<UnplacedAgentSummary> agents;
  final List<OrganizationUnit> units;

  @override
  State<_AssignExistingAgentDialog> createState() =>
      _AssignExistingAgentDialogState();
}

class _AssignExistingAgentDialogState
    extends State<_AssignExistingAgentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _agentId;
  String? _unitId;
  DateTime _startsAt = DateTime.now();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('umAssignExistingAgent')),
      content: SizedBox(
        width: 620,
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
                    labelText: l10n.lookup('umSelectUnplacedAgent'),
                  ),
                  items: widget.agents
                      .where((agent) => agent.isActive)
                      .map((agent) => DropdownMenuItem(
                            value: agent.id,
                            child: Text(
                              '${agent.displayName} · ${agent.email}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? l10n.lookup('umRequiredField') : null,
                  onChanged: (value) => setState(() => _agentId = value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _unitId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.lookup('umSelectUnit'),
                  ),
                  items: widget.units
                      .where((unit) => unit.isActive)
                      .map((unit) => DropdownMenuItem(
                            value: unit.id,
                            child: Text(unit.breadcrumb),
                          ))
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? l10n.lookup('umRequiredField') : null,
                  onChanged: (value) => setState(() => _unitId = value),
                ),
                _DateTile(
                  label: l10n.lookup('umAssignmentStartDate'),
                  value: _startsAt,
                  onSelected: (date) => setState(() => _startsAt = date),
                ),
                CommonTextInput(
                  label: l10n.lookup('umAssignmentReason'),
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
              ExistingAgentAssignmentFormResult(
                agentId: _agentId!,
                unitId: _unitId!,
                startsAt: _startsAt,
                reason: _reason.text.trim(),
              ),
            );
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _TransferAgentDialogState extends State<_TransferAgentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  OrganizationPlacementSelection _placement =
      const OrganizationPlacementSelection();
  DateTime _startsAt = DateTime.now();
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('umTransferAgent')),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OrganizationUnitHierarchySelector(
                  units: widget.units,
                  enabled: !_isSubmitting,
                  onChanged: (value) => _placement = value,
                ),
                _DateTile(
                  label: l10n.lookup('umAssignmentStartDate'),
                  value: _startsAt,
                  onSelected: (date) => setState(() => _startsAt = date),
                ),
                CommonTextInput(
                  label: l10n.lookup('umAssignmentReason'),
                  controller: _reason,
                  isMultiline: true,
                  validator: _required(l10n),
                ),
                if (_submissionError != null) ...[
                  const SizedBox(height: 16),
                  _SubmissionError(
                    key: const Key('organization-agent-transfer-error'),
                    message: _submissionError!,
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
                  key: const Key('organization-agent-transfer-progress'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(l10n.confirm),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final unitId = _placement.selectedUnitId!;
    if (unitId == widget.currentUnitId) {
      setState(() => _submissionError =
          S.of(context).lookup('umSelectDifferentOrganizationUnit'));
      return;
    }
    final result = OrganizationTransferFormResult(
      unitId: unitId,
      startsAt: _startsAt,
      reason: _reason.text.trim(),
      assignAsHead: _placement.assignAsHead,
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

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth >= 620
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    });
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      subtitle: Text('${value.day}/${value.month}/${value.year}'),
      onTap: () async {
        final today = DateUtils.dateOnly(DateTime.now());
        final selected = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2002),
          lastDate: today,
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
