import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

import '../reporting_administration_strings.dart';

class CatalogueItemDraftValue {
  const CatalogueItemDraftValue({
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.categoryId,
    required this.workflowId,
    required this.workflowVersion,
    required this.slaPolicyId,
    required this.slaPolicyVersion,
  });

  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String categoryId;
  final String workflowId;
  final int workflowVersion;
  final String slaPolicyId;
  final int slaPolicyVersion;

  Map<String, Object?> toPayload() => {
        'name': {'en': nameEn, 'fr': nameFr},
        'description': {'en': descriptionEn, 'fr': descriptionFr},
        'categoryId': categoryId,
        'workflow': {'id': workflowId, 'version': workflowVersion},
        'slaPolicy': {'id': slaPolicyId, 'version': slaPolicyVersion},
      };
}

class CatalogueItemForm extends StatefulWidget {
  const CatalogueItemForm({
    required this.onSubmit,
    super.key,
    this.initialValue,
    this.readOnly = false,
  });

  final CatalogueItemDraftValue? initialValue;
  final bool readOnly;
  final ValueChanged<CatalogueItemDraftValue> onSubmit;

  @override
  State<CatalogueItemForm> createState() => _CatalogueItemFormState();
}

class _CatalogueItemFormState extends State<CatalogueItemForm> {
  final _key = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers = [
    TextEditingController(text: widget.initialValue?.nameEn),
    TextEditingController(text: widget.initialValue?.nameFr),
    TextEditingController(text: widget.initialValue?.descriptionEn),
    TextEditingController(text: widget.initialValue?.descriptionFr),
    TextEditingController(text: widget.initialValue?.categoryId),
    TextEditingController(text: widget.initialValue?.workflowId),
    TextEditingController(text: '${widget.initialValue?.workflowVersion ?? 1}'),
    TextEditingController(text: widget.initialValue?.slaPolicyId),
    TextEditingController(
        text: '${widget.initialValue?.slaPolicyVersion ?? 1}'),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final labels = [
      strings.value('nameEnglish'),
      strings.value('nameFrench'),
      strings.value('descriptionEnglish'),
      strings.value('descriptionFrench'),
      strings.value('categoryId'),
      strings.value('workflowId'),
      strings.value('workflowVersion'),
      strings.value('slaPolicyId'),
      strings.value('slaVersion'),
    ];
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _controllers.length; index++) ...[
            CommonTextInput(
              label: labels[index],
              controller: _controllers[index],
              readOnly: widget.readOnly,
              isMultiline: index == 2 || index == 3,
              type: index == 6 || index == 8
                  ? CommonTextInputType.number
                  : CommonTextInputType.text,
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : strings.value('requiredField'),
            ),
            const SizedBox(height: 12),
          ],
          if (!widget.readOnly)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(strings.value('saveDraft')),
              ),
            ),
        ],
      ),
    );
  }

  void _submit() {
    if (_key.currentState?.validate() != true) return;
    widget.onSubmit(CatalogueItemDraftValue(
      nameEn: _controllers[0].text.trim(),
      nameFr: _controllers[1].text.trim(),
      descriptionEn: _controllers[2].text.trim(),
      descriptionFr: _controllers[3].text.trim(),
      categoryId: _controllers[4].text.trim(),
      workflowId: _controllers[5].text.trim(),
      workflowVersion: int.parse(_controllers[6].text),
      slaPolicyId: _controllers[7].text.trim(),
      slaPolicyVersion: int.parse(_controllers[8].text),
    ));
  }
}
