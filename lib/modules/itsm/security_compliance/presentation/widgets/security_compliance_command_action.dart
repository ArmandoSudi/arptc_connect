import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../../application/security_compliance_application.dart';
import '../security_compliance_strings.dart';

Future<bool> executeSecurityComplianceCommand(
  WidgetRef ref,
  BuildContext context, {
  required SecurityComplianceCommandType type,
  required Map<String, Object?> payload,
}) async {
  final strings = SecurityComplianceStrings.of(context);
  try {
    final session = await ref.read(itsmSessionProvider.future);
    if (session == null) return false;
    final nonce = DateTime.now().microsecondsSinceEpoch.toString();
    final controller =
        await ref.read(securityComplianceCommandControllerProvider.future);
    await controller.execute(
      SecurityComplianceCommand(
        context: ItsmCommandContext(
          idempotencyKey: '${type.command}:${session.userId}:$nonce',
          correlationId: 'security-compliance:$nonce',
          actorUserId: session.userId,
          actorDisplayName: session.displayName,
          actorRole: session.role,
        ),
        type: type,
        payload: payload,
      ),
    );
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.value('commandCompleted'))),
    );
    return true;
  } on Object {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.value('commandFailed'))),
    );
    return false;
  }
}
