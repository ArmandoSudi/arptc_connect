import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

import '../../domain/inventory_entities.dart';

class InventoryReasonField extends StatelessWidget {
  const InventoryReasonField({
    required this.options,
    required this.controller,
    required this.selectedReason,
    required this.onSelected,
    super.key,
  });

  final List<InventoryParameter> options;
  final TextEditingController controller;
  final String selectedReason;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final active = options.where((entry) => entry.isActive).toList();
    if (active.isEmpty) {
      return CommonTextInput(
        label: S.of(context).lookup('invReason'),
        controller: controller,
        isMultiline: true,
      );
    }
    return DropdownButtonFormField<String>(
      value: active.any((entry) => entry.name == selectedReason)
          ? selectedReason
          : null,
      decoration: InputDecoration(
        labelText: S.of(context).lookup('invReason'),
        hintText: S.of(context).lookup('invSelectReason'),
      ),
      items: [
        for (final option in active)
          DropdownMenuItem(value: option.name, child: Text(option.name)),
      ],
      onChanged: (value) => onSelected(value ?? ''),
    );
  }
}
