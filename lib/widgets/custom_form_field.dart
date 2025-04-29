
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomFormField extends StatelessWidget {
  const CustomFormField(
      {super.key,
      this.label,
      this.hintText,
      required this.textInputType,
      required this.controller,
      this.borderRadius = 5,
      this.inputFormatters,
      this.textInputAction,
      // this.maxLine = 1,
      this.validator,
      this.obscureText,
      this.enable,
      this.suffixIcon,
      this.prefixIcon,
      this.onTap,
      this.onChanged,
      this.prefix,
      this.onFieldSubmitted,
      this.focusNode});

  final String? label;
  final String? hintText;
  final TextInputType textInputType;
  final TextEditingController controller;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final double? borderRadius;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  final TextInputAction? textInputAction;

  // final int? maxLine;
  final bool? obscureText;
  final bool? enable;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label == null
            ? Container()
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 14,
                    // color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        TextFormField(
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.blue[10],
              prefixIcon: prefixIcon,
              prefix: prefix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(
                  Radius.circular(borderRadius ?? 5),
                ),
              ),
              suffixIcon: suffixIcon),
          controller: controller,
          keyboardType: textInputType,
          inputFormatters: inputFormatters,
          validator: validator,
          textInputAction: textInputAction,
          // maxLines: maxLine,
          obscureText: obscureText ?? false,
          enabled: enable ?? true,
          onTap: onTap,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
        ),
      ],
    );
  }
}
