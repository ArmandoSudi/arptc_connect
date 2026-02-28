import 'package:flutter/material.dart';

/// Material Design 3 Dropdown Field
///
/// A styled dropdown menu that follows M3 design guidelines
/// with proper surface tints and rounded corners
class CustomDropDown extends StatefulWidget {
  const CustomDropDown({
    super.key,
    this.label,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.initialValue,
  });

  final String hintText;
  final String? label;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? initialValue;

  @override
  State<CustomDropDown> createState() => _CustomDropDownState();
}

class _CustomDropDownState extends State<CustomDropDown> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              widget.label!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          dropdownColor: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          isExpanded: true,
          value: selectedValue,
          hint: Text(
            widget.hintText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          items: widget.items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedValue = value;
            });
            widget.onChanged?.call(value);
          },
        ),
      ],
    );
  }
}
