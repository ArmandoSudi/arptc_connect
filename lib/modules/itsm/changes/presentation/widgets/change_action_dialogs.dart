import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

import '../../domain/changes_domain.dart';
import '../change_presentation_strings.dart';

Future<Map<String, Object?>?> showChangeAssessmentDialog(
  BuildContext context,
  ChangeRequest change,
) {
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (context) => _AssessmentDialog(change: change),
  );
}

Future<Map<String, Object?>?> showChangeScheduleDialog(BuildContext context) {
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (context) => const _ScheduleDialog(),
  );
}

Future<Map<String, Object?>?> showChangeDecisionDialog(
  BuildContext context, {
  required String title,
  required List<String> decisions,
}) {
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (context) => _DecisionDialog(
      title: title,
      decisions: decisions,
    ),
  );
}

Future<String?> showChangeReasonDialog(
  BuildContext context, {
  required String title,
  bool required = true,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ReasonDialog(title: title, isRequired: required),
  );
}

Future<Map<String, Object?>?> showCabMeetingDialog(BuildContext context) {
  return showDialog<Map<String, Object?>>(
    context: context,
    builder: (context) => const _CabMeetingDialog(),
  );
}

class _CabMeetingDialog extends StatefulWidget {
  const _CabMeetingDialog();

  @override
  State<_CabMeetingDialog> createState() => _CabMeetingDialogState();
}

class _CabMeetingDialogState extends State<_CabMeetingDialog> {
  final _key = GlobalKey<FormState>();
  final _group = TextEditingController();
  final _title = TextEditingController();
  final _agenda = TextEditingController();
  final _participants = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _group,
      _title,
      _agenda,
      _participants,
      _start,
      _end,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.cabMeeting),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonTextInput(
                  label: l10n.cabApprovalGroup,
                  controller: _group,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.title,
                  controller: _title,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.calendarAgenda,
                  controller: _agenda,
                  isMultiline: true,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.cabParticipantIds,
                  controller: _participants,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: '${l10n.plannedStart} (ISO 8601)',
                  controller: _start,
                  validator: _date,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: '${l10n.plannedEnd} (ISO 8601)',
                  controller: _end,
                  validator: _date,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.cabMeetingNotes,
                  controller: _notes,
                  isMultiline: true,
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
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }

  String? _required(String? value) =>
      value?.trim().isEmpty ?? true ? S.of(context).requiredField : null;

  String? _date(String? value) => DateTime.tryParse(value ?? '') == null
      ? S.of(context).requiredField
      : null;

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(context, {
      'approvalGroupId': _group.text.trim(),
      'title': _title.text.trim(),
      'agenda': _agenda.text.trim(),
      'participantUserIds': _ids(_participants.text),
      'scheduledStartAt':
          DateTime.parse(_start.text.trim()).toUtc().toIso8601String(),
      'scheduledEndAt':
          DateTime.parse(_end.text.trim()).toUtc().toIso8601String(),
      'notes': _notes.text.trim(),
    });
  }
}

class _AssessmentDialog extends StatefulWidget {
  const _AssessmentDialog({required this.change});

  final ChangeRequest change;

  @override
  State<_AssessmentDialog> createState() => _AssessmentDialogState();
}

class _AssessmentDialogState extends State<_AssessmentDialog> {
  final _key = GlobalKey<FormState>();
  late final _owner = TextEditingController(
    text: widget.change.owner?.userId ?? '',
  );
  final _services = TextEditingController();
  final _cis = TextEditingController();
  final _assets = TextEditingController();
  final _incidents = TextEditingController();
  final _requests = TextEditingController();
  final _downtime = TextEditingController(text: '0');
  final _implementation = TextEditingController();
  final _test = TextEditingController();
  final _communication = TextEditingController();
  final _rollback = TextEditingController();
  final _approvalGroup = TextEditingController();
  String _impact = 'medium';
  String _urgency = 'medium';
  String _complexity = 'medium';

  @override
  void dispose() {
    for (final controller in [
      _owner,
      _services,
      _cis,
      _assets,
      _incidents,
      _requests,
      _downtime,
      _implementation,
      _test,
      _communication,
      _rollback,
      _approvalGroup,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.assessChange),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonTextInput(
                  label: l10n.changeOwner,
                  controller: _owner,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.affectedServices,
                  controller: _services,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.affectedConfigurationItems,
                  controller: _cis,
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.affectedAssets,
                  controller: _assets,
                ),
                const SizedBox(height: 12),
                _LevelSelectors(
                  impact: _impact,
                  urgency: _urgency,
                  complexity: _complexity,
                  onImpact: (value) => setState(() => _impact = value),
                  onUrgency: (value) => setState(() => _urgency = value),
                  onComplexity: (value) => setState(() => _complexity = value),
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.expectedDowntime,
                  type: CommonTextInputType.number,
                  controller: _downtime,
                  validator: (value) => int.tryParse(value ?? '') == null
                      ? l10n.requiredField
                      : null,
                ),
                for (final entry in [
                  (l10n.implementationPlan, _implementation),
                  (l10n.testPlan, _test),
                  (l10n.communicationPlan, _communication),
                  (l10n.rollbackPlan, _rollback),
                ]) ...[
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: entry.$1,
                    controller: entry.$2,
                    isMultiline: true,
                    validator: _required,
                  ),
                ],
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.itsmApprovalsCab,
                  controller: _approvalGroup,
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
          onPressed: _submit,
          child: Text(l10n.assessChange),
        ),
      ],
    );
  }

  String? _required(String? value) =>
      value?.trim().isEmpty ?? true ? S.of(context).requiredField : null;

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(context, {
      'ownerUserId': _owner.text.trim(),
      'affectedServiceIds': _ids(_services.text),
      'affectedCiIds': _ids(_cis.text),
      'affectedAssetIds': _ids(_assets.text),
      'relatedIncidentIds': _ids(_incidents.text),
      'relatedRequestIds': _ids(_requests.text),
      'impact': _impact,
      'urgency': _urgency,
      'complexity': _complexity,
      'expectedDowntimeMinutes': int.parse(_downtime.text.trim()),
      'implementationPlan': _implementation.text.trim(),
      'testPlan': _test.text.trim(),
      'testEvidenceAttachmentIds': <String>[],
      'communicationPlan': _communication.text.trim(),
      'rollbackPlan': _rollback.text.trim(),
      'approvalGroupId': _optional(_approvalGroup.text),
    });
  }
}

class _LevelSelectors extends StatelessWidget {
  const _LevelSelectors({
    required this.impact,
    required this.urgency,
    required this.complexity,
    required this.onImpact,
    required this.onUrgency,
    required this.onComplexity,
  });

  final String impact;
  final String urgency;
  final String complexity;
  final ValueChanged<String> onImpact;
  final ValueChanged<String> onUrgency;
  final ValueChanged<String> onComplexity;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _dropdown(context, l10n.impact, impact, onImpact,
            includeCritical: true),
        _dropdown(context, l10n.urgency, urgency, onUrgency),
        _dropdown(context, l10n.changeComplexity, complexity, onComplexity),
      ],
    );
  }

  Widget _dropdown(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool includeCritical = false,
  }) {
    final values = ['low', 'medium', 'high', if (includeCritical) 'critical'];
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in values)
            DropdownMenuItem(
              value: option,
              child: Text(
                S.of(context).changeRiskLabel(
                      ChangeRiskLevel.fromValue(option),
                    ),
              ),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog();

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _key = GlobalKey<FormState>();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _downtime = TextEditingController(text: '0');
  final _maintenanceWindow = TextEditingController();
  bool _publish = false;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _downtime.dispose();
    _maintenanceWindow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.scheduleChange),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CommonTextInput(
                label: '${l10n.plannedStart} (ISO 8601)',
                controller: _start,
                validator: _date,
              ),
              const SizedBox(height: 12),
              CommonTextInput(
                label: '${l10n.plannedEnd} (ISO 8601)',
                controller: _end,
                validator: _date,
              ),
              const SizedBox(height: 12),
              CommonTextInput(
                label: l10n.expectedDowntime,
                type: CommonTextInputType.number,
                controller: _downtime,
              ),
              const SizedBox(height: 12),
              CommonTextInput(
                label: l10n.maintenanceWindow,
                controller: _maintenanceWindow,
              ),
              CheckboxListTile(
                value: _publish,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.maintenancePublished),
                onChanged: (value) => setState(() => _publish = value ?? false),
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
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            Navigator.pop(context, {
              'plannedStartAt':
                  DateTime.parse(_start.text.trim()).toUtc().toIso8601String(),
              'plannedEndAt':
                  DateTime.parse(_end.text.trim()).toUtc().toIso8601String(),
              'expectedDowntimeMinutes':
                  int.tryParse(_downtime.text.trim()) ?? 0,
              'maintenanceWindowId': _optional(_maintenanceWindow.text),
              'publishMaintenance': _publish,
            });
          },
          child: Text(l10n.scheduleChange),
        ),
      ],
    );
  }

  String? _date(String? value) => DateTime.tryParse(value ?? '') == null
      ? S.of(context).requiredField
      : null;
}

class _DecisionDialog extends StatefulWidget {
  const _DecisionDialog({required this.title, required this.decisions});

  final String title;
  final List<String> decisions;

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  late String _decision = widget.decisions.first;
  final _comment = TextEditingController();
  final _conditions = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    _conditions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _decision,
              items: [
                for (final decision in widget.decisions)
                  DropdownMenuItem(
                    value: decision,
                    child: Text(_decisionLabel(l10n, decision)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _decision = value ?? _decision),
            ),
            const SizedBox(height: 12),
            CommonTextInput(
              label: l10n.decisionComment,
              controller: _comment,
              isMultiline: true,
            ),
            const SizedBox(height: 12),
            CommonTextInput(
              label: l10n.approvalConditions,
              controller: _conditions,
              isMultiline: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'decision': _decision,
            'comment': _comment.text.trim().isEmpty
                ? _decision.replaceAll('_', ' ')
                : _comment.text.trim(),
            'conditions': _ids(_conditions.text),
          }),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.isRequired});

  final String title;
  final bool isRequired;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _key = GlobalKey<FormState>();
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
      content: Form(
        key: _key,
        child: SizedBox(
          width: 520,
          child: CommonTextInput(
            label: l10n.decisionComment,
            controller: _reason,
            isMultiline: true,
            validator: (value) =>
                widget.isRequired && (value?.trim().isEmpty ?? true)
                    ? l10n.changeReasonRequired
                    : null,
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
            if (!_key.currentState!.validate()) return;
            Navigator.pop(context, _reason.text.trim());
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

List<String> _ids(String value) => value
    .split(RegExp(r'[,\n]'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toSet()
    .toList(growable: false);

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String _decisionLabel(S l10n, String decision) => switch (decision) {
      'approved' => l10n.approveChange,
      'rejected' => l10n.rejectChange,
      'clarification_requested' => l10n.requestClarification,
      'succeeded' || 'successful' => l10n.changeOutcomeSuccessful,
      'partial' => l10n.changeOutcomePartial,
      'failed' || 'unsuccessful' => l10n.changeOutcomeFailed,
      'rolled_back' => l10n.changeOutcomeRolledBack,
      _ => decision,
    };
