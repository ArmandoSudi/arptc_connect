import 'dart:collection';

import '../../shared/data/trusted_command_gateways.dart';

enum ChangeCommandType {
  initializeDraft('change.initialize_draft', 'itsmInitializeChangeDraft'),
  saveDraft('change.save_draft', 'itsmSaveChangeDraft'),
  submit('change.submit', 'itsmSubmitChange'),
  cancel('change.cancel', 'itsmCancelChange'),
  assess('change.assess', 'itsmAssessChange'),
  requestApproval('change.approval.request', 'itsmRequestChangeApproval'),
  decideApproval('change.approval.decide', 'itsmDecideChangeApproval'),
  saveCabMeeting('change.cab_meeting.save', 'itsmSaveChangeCabMeeting'),
  schedule('change.schedule', 'itsmScheduleChange'),
  startImplementation(
    'change.implementation.start',
    'itsmStartChangeImplementation',
  ),
  recordImplementationResult(
    'change.implementation.record_result',
    'itsmRecordChangeImplementationResult',
  ),
  recordPostImplementationReview(
    'change.pir.record',
    'itsmRecordChangePostImplementationReview',
  ),
  close('change.close', 'itsmCloseChange');

  const ChangeCommandType(this.command, this.functionName);

  final String command;
  final String functionName;

  bool get isSelfService => switch (this) {
        initializeDraft || saveDraft || submit || cancel => true,
        _ => false,
      };
}

class ChangeCommand {
  ChangeCommand({
    required this.context,
    required this.type,
    required Map<String, Object?> payload,
  }) : payload = UnmodifiableMapView(Map<String, Object?>.from(payload));

  final ItsmCommandContext context;
  final ChangeCommandType type;
  final Map<String, Object?> payload;
}

abstract interface class ChangeCommandGateway {
  Future<ItsmCommandReceipt> execute(ChangeCommand command);
}
