import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

import '../reporting_administration_strings.dart';

class SlaPolicyDraftValue {
  const SlaPolicyDraftValue({
    required this.name,
    required this.timeZone,
    required this.responseTargetMinutes,
    required this.resolutionTargetMinutes,
    required this.warningThreshold,
    required this.weekdayStartMinutes,
    required this.weekdayEndMinutes,
    required this.holidays,
    required this.pauseStatuses,
  });

  final String name;
  final String timeZone;
  final int responseTargetMinutes;
  final int resolutionTargetMinutes;
  final double warningThreshold;
  final int weekdayStartMinutes;
  final int weekdayEndMinutes;
  final List<String> holidays;
  final List<String> pauseStatuses;

  Map<String, Object?> toPayload() => {
        'name': name,
        'timeZone': timeZone,
        'responseTargetMinutes': responseTargetMinutes,
        'resolutionTargetMinutes': resolutionTargetMinutes,
        'warningThreshold': warningThreshold,
        'pauseStatuses': pauseStatuses,
        'calendar': {
          'weeklyWindows': {
            for (var day = DateTime.monday; day <= DateTime.friday; day++)
              '$day': [
                {
                  'startMinutes': weekdayStartMinutes,
                  'endMinutes': weekdayEndMinutes,
                }
              ],
          },
          'holidays': holidays,
        },
      };
}

class SlaPolicyForm extends StatefulWidget {
  const SlaPolicyForm({
    required this.onSubmit,
    super.key,
    this.initialValue,
    this.readOnly = false,
  });

  final SlaPolicyDraftValue? initialValue;
  final bool readOnly;
  final ValueChanged<SlaPolicyDraftValue> onSubmit;

  @override
  State<SlaPolicyForm> createState() => _SlaPolicyFormState();
}

class _SlaPolicyFormState extends State<SlaPolicyForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialValue?.name);
  late final _timeZone = TextEditingController(
    text: widget.initialValue?.timeZone ?? 'Africa/Kinshasa',
  );
  late final _response = TextEditingController(
    text: '${widget.initialValue?.responseTargetMinutes ?? 60}',
  );
  late final _resolution = TextEditingController(
    text: '${widget.initialValue?.resolutionTargetMinutes ?? 480}',
  );
  late final _warning = TextEditingController(
    text: '${widget.initialValue?.warningThreshold ?? .8}',
  );
  late final _start = TextEditingController(
    text: '${widget.initialValue?.weekdayStartMinutes ?? 480}',
  );
  late final _end = TextEditingController(
    text: '${widget.initialValue?.weekdayEndMinutes ?? 1020}',
  );
  late final _holidays = TextEditingController(
    text: widget.initialValue?.holidays.join(', ') ?? '',
  );
  late final _pauses = TextEditingController(
    text: widget.initialValue?.pauseStatuses.join(', ') ?? '',
  );

  @override
  void dispose() {
    for (final controller in [
      _name,
      _timeZone,
      _response,
      _resolution,
      _warning,
      _start,
      _end,
      _holidays,
      _pauses,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommonTextInput(
            label: strings.value('policyName'),
            controller: _name,
            readOnly: widget.readOnly,
            validator: _required,
          ),
          const SizedBox(height: 12),
          CommonTextInput(
            label: strings.value('timeZone'),
            controller: _timeZone,
            readOnly: widget.readOnly,
            validator: _required,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth >= 640
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: CommonTextInput(
                    label: strings.value('responseTarget'),
                    type: CommonTextInputType.number,
                    controller: _response,
                    readOnly: widget.readOnly,
                    validator: _positive,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: CommonTextInput(
                    label: strings.value('resolutionTarget'),
                    type: CommonTextInputType.number,
                    controller: _resolution,
                    readOnly: widget.readOnly,
                    validator: _positive,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: CommonTextInput(
                    label: strings.value('weekdayStart'),
                    type: CommonTextInputType.number,
                    controller: _start,
                    readOnly: widget.readOnly,
                    validator: _minutes,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: CommonTextInput(
                    label: strings.value('weekdayEnd'),
                    type: CommonTextInputType.number,
                    controller: _end,
                    readOnly: widget.readOnly,
                    validator: _minutes,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          CommonTextInput(
            label: strings.value('warningThreshold'),
            type: CommonTextInputType.decimal,
            controller: _warning,
            readOnly: widget.readOnly,
            validator: _threshold,
          ),
          const SizedBox(height: 12),
          CommonTextInput(
            label: strings.value('holidays'),
            controller: _holidays,
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 12),
          CommonTextInput(
            label: strings.value('pauseStatuses'),
            controller: _pauses,
            readOnly: widget.readOnly,
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: 18),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(strings.value('saveDraft')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _submit() {
    if (_key.currentState?.validate() != true) return;
    final start = int.parse(_start.text);
    final end = int.parse(_end.text);
    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ReportingAdministrationStrings.of(context)
                .value('businessHoursOrder'),
          ),
        ),
      );
      return;
    }
    widget.onSubmit(SlaPolicyDraftValue(
      name: _name.text.trim(),
      timeZone: _timeZone.text.trim(),
      responseTargetMinutes: int.parse(_response.text),
      resolutionTargetMinutes: int.parse(_resolution.text),
      warningThreshold: double.parse(_warning.text.replaceAll(',', '.')),
      weekdayStartMinutes: start,
      weekdayEndMinutes: end,
      holidays: _csv(_holidays.text),
      pauseStatuses: _csv(_pauses.text),
    ));
  }

  String? _required(String? value) => value?.trim().isNotEmpty == true
      ? null
      : ReportingAdministrationStrings.of(context).value('requiredField');
  String? _positive(String? value) => (int.tryParse(value ?? '') ?? 0) > 0
      ? null
      : ReportingAdministrationStrings.of(context).value('positiveNumber');
  String? _minutes(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed != null && parsed >= 0 && parsed <= 1440
        ? null
        : ReportingAdministrationStrings.of(context).value('minutesRange');
  }

  String? _threshold(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    return parsed != null && parsed > 0 && parsed < 1
        ? null
        : ReportingAdministrationStrings.of(context).value('thresholdRange');
  }
}

List<String> _csv(String value) => value
    .split(',')
    .map((part) => part.trim())
    .where((part) => part.isNotEmpty)
    .toList(growable: false);
