import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {

  final String text;
  final VoidCallback? onPressed;
  const CustomFilledButton({super.key, required this.text, required this.onPressed });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
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
