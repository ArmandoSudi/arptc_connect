import 'package:flutter/material.dart';

class CustomDropDown extends StatefulWidget {
  CustomDropDown({
    super.key,
    this.label,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String hintText;
  String? label;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  @override
  State<CustomDropDown> createState() => _CustomDropDownState();
}

class _CustomDropDownState extends State<CustomDropDown> {

  String? selectedValue;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label == null ? Container() : Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
              widget.label!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            hintText: widget.hintText,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular( 5)
                )
            ),
            // suffixIcon: Icon(Icons.arrow_drop_down)
          ),
          icon: const Icon(Icons.keyboard_arrow_down_outlined),
          isExpanded: true,
          value: selectedValue,
          items: widget.items
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
