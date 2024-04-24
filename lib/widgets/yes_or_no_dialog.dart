import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<bool?> showYesNoDialog(BuildContext context, String title, String content) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Oui'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Non'),
        ),
      ],
    ),
  );
  return result;
}

Future<bool?> showCupertinoYesNoDialog(BuildContext context, String title, String content) async {
  final result = await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          child: const Text('Oui'),
          onPressed: () => Navigator.pop(context, true),
        ),
        CupertinoDialogAction(
          child: const Text('Non'),
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  return result;
}