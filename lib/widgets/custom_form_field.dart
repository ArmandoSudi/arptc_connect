
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material Design 3 Form Field
///
/// Features:
/// - Filled container with proper tonal colors
/// - Label animation with proper contrast
/// - Error state styling
/// - Support for prefix/suffix icons
class CustomFormField extends StatelessWidget {
  const CustomFormField(
      {super.key,
      this.label,
      this.hintText,
      required this.textInputType,
      required this.controller,
      this.borderRadius = 12,
      this.inputFormatters,
      this.textInputAction,
      this.validator,
      this.obscureText,
      this.enable,
      this.suffixIcon,
      this.prefixIcon,
      this.onTap,
      this.onChanged,
      this.prefix,
      this.onFieldSubmitted,
      this.focusNode,
      this.maxLines = 1,
      this.minLines});

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

  final int? maxLines;
  final int? minLines;
  final bool? obscureText;
  final bool? enable;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextFormField(
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            prefix: prefix,
            hintText: hintText,
            suffixIcon: suffixIcon,
          ),
          controller: controller,
          keyboardType: textInputType,
          inputFormatters: inputFormatters,
          validator: validator,
          textInputAction: textInputAction,
          maxLines: maxLines,
          minLines: minLines,
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

