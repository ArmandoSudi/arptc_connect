import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Material Design 3 Confirmation Dialog
///
/// Shows a dialog with Yes/No actions following M3 guidelines:
/// - Icon for visual indication
/// - Clear title and content
/// - Properly styled action buttons
Future<bool?> showYesNoDialog(
  BuildContext context,
  String title,
  String content, {
  IconData? icon,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
}) async {
  final colorScheme = Theme.of(context).colorScheme;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: icon != null
          ? Icon(
              icon,
              size: 24,
              color: isDestructive ? colorScheme.error : colorScheme.primary,
            )
          : null,
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText ?? 'Non'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmText ?? 'Oui'),
        ),
      ],
    ),
  );
  return result;
}

/// Adaptive Confirmation Dialog
///
/// Shows a native-looking dialog based on platform:
/// - Cupertino on iOS/macOS
/// - Material on other platforms
Future<bool?> showAdaptiveYesNoDialog(
  BuildContext context,
  String title,
  String content, {
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
}) async {
  final theme = Theme.of(context);
  final isApple = theme.platform == TargetPlatform.iOS ||
                  theme.platform == TargetPlatform.macOS;

  if (isApple) {
    return showCupertinoYesNoDialog(
      context,
      title,
      content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    );
  } else {
    return showYesNoDialog(
      context,
      title,
      content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    );
  }
}

Future<bool?> showCupertinoYesNoDialog(
  BuildContext context,
  String title,
  String content, {
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
}) async {
  final result = await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText ?? 'Non'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          isDefaultAction: !isDestructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText ?? 'Oui'),
        ),
      ],
    ),
  );
  return result;
}