import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

class SecurityDialogField {
  const SecurityDialogField({
    required this.keyName,
    required this.label,
    this.multiline = false,
    this.required = true,
    this.initialValue = '',
    this.options = const [],
  });

  final String keyName;
  final String label;
  final bool multiline;
  final bool required;
  final String initialValue;
  final List<SecurityDialogOption> options;
}

class SecurityDialogOption {
  const SecurityDialogOption(this.value, this.label);

  final String value;
  final String label;
}

Future<Map<String, String>?> showSecurityComplianceActionDialog(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required String cancelLabel,
  required String requiredFieldLabel,
  required List<SecurityDialogField> fields,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _SecurityComplianceActionDialog(
      title: title,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
      requiredFieldLabel: requiredFieldLabel,
      fields: fields,
    ),
  );
}

class _SecurityComplianceActionDialog extends StatefulWidget {
  const _SecurityComplianceActionDialog({
    required this.title,
    required this.submitLabel,
    required this.cancelLabel,
    required this.requiredFieldLabel,
    required this.fields,
  });

  final String title;
  final String submitLabel;
  final String cancelLabel;
  final String requiredFieldLabel;
  final List<SecurityDialogField> fields;

  @override
  State<_SecurityComplianceActionDialog> createState() =>
      _SecurityComplianceActionDialogState();
}

class _SecurityComplianceActionDialogState
    extends State<_SecurityComplianceActionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.fields)
      if (field.options.isEmpty)
        field.keyName: TextEditingController(text: field.initialValue),
  };
  late final Map<String, String?> _selectedValues = {
    for (final field in widget.fields)
      if (field.options.isNotEmpty)
        field.keyName: field.initialValue.isNotEmpty
            ? field.initialValue
            : field.options.first.value,
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < widget.fields.length; index++) ...[
                  if (widget.fields[index].options.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedValues[widget.fields[index].keyName],
                      decoration: InputDecoration(
                        labelText: widget.fields[index].label,
                      ),
                      items: [
                        for (final option in widget.fields[index].options)
                          DropdownMenuItem(
                            value: option.value,
                            child: Text(option.label),
                          ),
                      ],
                      validator: widget.fields[index].required
                          ? (value) => value == null || value.trim().isEmpty
                              ? widget.requiredFieldLabel
                              : null
                          : null,
                      onChanged: (value) => setState(
                        () => _selectedValues[widget.fields[index].keyName] =
                            value,
                      ),
                    )
                  else
                    CommonTextInput(
                      label: widget.fields[index].label,
                      controller: _controllers[widget.fields[index].keyName],
                      isMultiline: widget.fields[index].multiline,
                      validator: widget.fields[index].required
                          ? (value) => value == null || value.trim().isEmpty
                              ? widget.requiredFieldLabel
                              : null
                          : null,
                    ),
                  if (index < widget.fields.length - 1)
                    const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop({
              for (final entry in _controllers.entries)
                entry.key: entry.value.text.trim(),
              for (final entry in _selectedValues.entries)
                if (entry.value != null) entry.key: entry.value!,
            });
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
