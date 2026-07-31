import 'package:arptc_connect/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CommonTextInputType {
  text,
  name,
  number,
  decimal,
  email,
  phone,
  url,
  dateTime,
}

class CommonTextInput extends StatelessWidget {
  const CommonTextInput({
    required this.label,
    super.key,
    this.type = CommonTextInputType.text,
    this.isPassword = false,
    this.isMultiline = false,
    this.controller,
    this.initialValue,
    this.hintText,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.prefix,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.minLines,
    this.maxLines,
    this.decoration,
    this.borderRadius,
  });

  final String label;
  final CommonTextInputType type;
  final bool isPassword;
  final bool isMultiline;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final int? minLines;
  final int? maxLines;
  final InputDecoration? decoration;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.corporateTheme;
    final resolvedMaxLines = isPassword ? 1 : maxLines ?? (isMultiline ? 5 : 1);
    final resolvedMinLines = isPassword ? 1 : minLines ?? (isMultiline ? 3 : 1);
    final baseDecoration = decoration ?? const InputDecoration();
    final resolvedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        borderRadius ?? tokens.controlRadius,
      ),
      borderSide: BorderSide(
        color: colorScheme.primary.withOpacity(0.45),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          style: theme.textTheme.bodyLarge,
          keyboardType: _keyboardType,
          inputFormatters: inputFormatters ?? _defaultInputFormatters,
          validator: validator,
          textInputAction: textInputAction ??
              (isMultiline ? TextInputAction.newline : TextInputAction.next),
          minLines: resolvedMinLines,
          maxLines: resolvedMaxLines,
          obscureText: isPassword,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          onTap: onTap,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          decoration: baseDecoration.copyWith(
            hintText: hintText ?? baseDecoration.hintText,
            prefix: prefix ?? baseDecoration.prefix,
            prefixIcon: prefixIcon ?? baseDecoration.prefixIcon,
            suffixIcon: suffixIcon ?? baseDecoration.suffixIcon,
            border: baseDecoration.border ?? resolvedBorder,
            enabledBorder: baseDecoration.enabledBorder ?? resolvedBorder,
            focusedBorder: baseDecoration.focusedBorder ??
                resolvedBorder.copyWith(
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  TextInputType get _keyboardType {
    switch (type) {
      case CommonTextInputType.text:
        return isMultiline ? TextInputType.multiline : TextInputType.text;
      case CommonTextInputType.name:
        return TextInputType.name;
      case CommonTextInputType.number:
        return TextInputType.number;
      case CommonTextInputType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case CommonTextInputType.email:
        return TextInputType.emailAddress;
      case CommonTextInputType.phone:
        return TextInputType.phone;
      case CommonTextInputType.url:
        return TextInputType.url;
      case CommonTextInputType.dateTime:
        return TextInputType.datetime;
    }
  }

  List<TextInputFormatter>? get _defaultInputFormatters {
    switch (type) {
      case CommonTextInputType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case CommonTextInputType.decimal:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*$')),
        ];
      case CommonTextInputType.text:
      case CommonTextInputType.name:
      case CommonTextInputType.email:
      case CommonTextInputType.phone:
      case CommonTextInputType.url:
      case CommonTextInputType.dateTime:
        return null;
    }
  }
}
