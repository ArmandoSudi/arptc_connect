import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {

  final String text;
  Color? backgroundColor;
  final VoidCallback? onPressed;
  CustomFilledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: backgroundColor ?? theme.buttonTheme.colorScheme?.primary,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
