import 'dart:developer' as developer;

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:flutter/material.dart';

typedef UserManagementErrorLogger = void Function(
  String message, {
  Object? error,
  StackTrace? stackTrace,
});

String userManagementCommandErrorMessage(S l10n, Object error) {
  final code = switch (error) {
    OrganizationCommandException exception => exception.code,
    AgentProvisioningException exception => exception.code,
    _ => '',
  };
  final rawMessage = switch (error) {
    OrganizationCommandException exception => exception.message,
    AgentProvisioningException exception => exception.message,
    _ => error.toString(),
  }
      .trim();
  final genericInternal = code == 'internal' &&
      (rawMessage.isEmpty || rawMessage.toLowerCase() == 'internal');
  if (genericInternal ||
      const {'not-found', 'unavailable', 'unimplemented'}.contains(code)) {
    return l10n.lookup('umOrganizationServiceUnavailable');
  }
  return rawMessage.isEmpty ? l10n.lookup('umCommandFailed') : rawMessage;
}

void reportUserManagementCommandError(
  BuildContext context, {
  required String operation,
  required Object error,
  required StackTrace stackTrace,
  String? userMessage,
  UserManagementErrorLogger logger = _defaultLogger,
}) {
  logUserManagementCommandError(
    operation: operation,
    error: error,
    stackTrace: stackTrace,
    logger: logger,
  );
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          userMessage ??
              userManagementCommandErrorMessage(S.of(context), error),
        ),
      ),
    );
}

void logUserManagementCommandError({
  required String operation,
  required Object error,
  required StackTrace stackTrace,
  UserManagementErrorLogger logger = _defaultLogger,
}) {
  logger(
    'User Management operation "$operation" failed.',
    error: error,
    stackTrace: stackTrace,
  );
}

void _defaultLogger(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    name: 'arptc_connect.user_management',
    error: error,
    stackTrace: stackTrace,
    level: 1000,
  );
}
