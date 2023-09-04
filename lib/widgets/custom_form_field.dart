import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomFormField extends StatelessWidget {

  const CustomFormField({
    Key? key,
    this.label,
    required this.hintText,
    required this.textInputType,
    required this.controller,
    this.inputFormatters,
    this.maxLine,
    this.validator,
    this.obscureText}) : super(key: key);

  final String? label;
  final String hintText;
  final TextInputType textInputType;
  final TextEditingController controller;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int? maxLine;
  final bool? obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label == null ? Container() : Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
              label!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ),
        TextFormField(
          style: TextStyle(fontSize: 18),
          decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              hintText: hintText,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                      Radius.circular(40)
                  )
              )

          ),
          controller: controller,
          keyboardType: textInputType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLine,
          obscureText: obscureText ?? false,
        ),
      ],
    );
  }
}