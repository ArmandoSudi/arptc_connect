import 'dart:async';
import 'dart:typed_data';

import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/approval.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/support/application/service_request_access_policy.dart';
import 'package:arptc_connect/modules/itsm/support/application/service_request_controller.dart';
import 'package:arptc_connect/modules/itsm/support/data/firebase_service_request_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/support/data/service_request_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/support/domain/support_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support_test_fixtures.dart';

void main() {
  group('FirebaseServiceRequestCommandGateway', () {
    test('initializes draft, uploads, waits for registration, then submits',
        () async {
      final invoker = _RecordingInvoker([
        {
          'requestId': 'request-42',
          'requestNumber': 'REQ-2026-0042',
          'status': 'draft',
          'uploadPath': 'itsm/serviceRequests/request-42/attachments',
        },
        {
          'requestId': 'request-42',
          'requestNumber': 'REQ-2026-0042',
          'status': 'submitted',
        },
      ]);
      final uploader = _RecordingUploader();
      final probe = _RegistrationProbe([false, true]);
      var delays = 0;
      final gateway = FirebaseServiceRequestCommandGateway(
        invoker,
        attachmentUploader: uploader,
        registrationProbe: probe,
        delay: (_) async => delays++,
      );

      final receipt = await gateway.create(_createCommand());

      expect(invoker.calls, hasLength(2));
      expect(invoker.calls.first.functionName,
          'itsmInitializeServiceRequestDraft');
      expect(invoker.calls.first.payload['command'],
          'service_request.initialize_draft');
      expect(invoker.calls.first.payload['idempotencyKey'],
          'request-command-123.draft');
      final initializePayload =
          invoker.calls.first.payload['payload']! as Map<String, Object?>;
      expect(initializePayload['requestedForUserId'], 'user-1');
      expect(initializePayload['responses'], {'title': 'Unable to connect'});
      expect(initializePayload, isNot(contains('documents')));

      expect(uploader.uploads, hasLength(1));
      final upload = uploader.uploads.single;
      expect(
        upload.storagePath,
        'itsm/serviceRequests/request-42/attachments/'
        'attachment-1/proof.pdf',
      );
      expect(upload.customMetadata, {
        'workItemCollection': 'serviceRequests',
        'workItemId': 'request-42',
        'attachmentId': 'attachment-1',
        'uploadedByUserId': 'user-1',
        'documentRequirementKey': 'proof',
        'isInternal': 'false',
      });
      expect(probe.calls, 2);
      expect(delays, 1);

      expect(invoker.calls.last.functionName, 'itsmSubmitServiceRequest');
      expect(
        invoker.calls.last.payload['idempotencyKey'],
        'request-command-123.submit',
      );
      expect(invoker.calls.last.payload['command'], 'service_request.submit');
      final submitPayload =
          invoker.calls.last.payload['payload']! as Map<String, Object?>;
      expect(submitPayload, {
        'requestId': 'request-42',
        'responses': {'title': 'Unable to connect'},
        'attachmentIds': ['attachment-1'],
      });
      expect(receipt.requestId, 'request-42');
      expect(receipt.status, ServiceRequestStatus.submitted);
      expect(receipt.workflowVersion, 3);
      expect(receipt.slaPolicyVersion, 4);
    });

    test('does not submit when an attachment upload fails', () async {
      final invoker = _RecordingInvoker([_draftResult()]);
      final gateway = FirebaseServiceRequestCommandGateway(
        invoker,
        attachmentUploader: _RecordingUploader(error: StateError('offline')),
        registrationProbe: _RegistrationProbe([true]),
        delay: (_) async {},
      );

      await expectLater(
        gateway.create(_createCommand()),
        throwsA(
          isA<ServiceRequestAttachmentUploadException>().having(
            (error) => error.attachmentId,
            'attachmentId',
            'attachment-1',
          ),
        ),
      );

      expect(invoker.calls, hasLength(1));
    });

    test('times out after bounded attachment registration attempts', () async {
      final invoker = _RecordingInvoker([_draftResult()]);
      final probe = _RegistrationProbe([false, false, false]);
      var delays = 0;
      final gateway = FirebaseServiceRequestCommandGateway(
        invoker,
        attachmentUploader: _RecordingUploader(),
        registrationProbe: probe,
        registrationAttempts: 3,
        registrationPollInterval: const Duration(milliseconds: 1),
        delay: (_) async => delays++,
      );

      await expectLater(
        gateway.create(_createCommand()),
        throwsA(
          isA<ServiceRequestAttachmentRegistrationTimeoutException>().having(
            (error) => error.attachmentId,
            'attachmentId',
            'attachment-1',
          ),
        ),
      );

      expect(probe.calls, 3);
      expect(delays, 2);
      expect(invoker.calls, hasLength(1));
    });

    test('preserves duplicate status from final submit receipt', () async {
      final invoker = _RecordingInvoker([
        _draftResult(),
        {
          'requestId': 'request-42',
          'requestNumber': 'REQ-2026-0042',
          'status': 'submitted',
          'wasDuplicate': true,
        },
      ]);
      final gateway = FirebaseServiceRequestCommandGateway(
        invoker,
        attachmentUploader: _RecordingUploader(),
        registrationProbe: _RegistrationProbe([true]),
        delay: (_) async {},
      );

      final receipt = await gateway.create(_createCommand());

      expect(receipt.command.wasDuplicate, isTrue);
      expect(invoker.calls, hasLength(2));
    });

    test('keeps trusted transition and approval envelopes', () async {
      final invoker = _RecordingInvoker([
        {'commandId': 'command-1'},
        {'commandId': 'command-2'},
      ]);
      final gateway = FirebaseServiceRequestCommandGateway(
        invoker,
        attachmentUploader: _RecordingUploader(),
        registrationProbe: _RegistrationProbe(const []),
      );
      final context = _context();

      await gateway.transition(
        TransitionServiceRequestCommand(
          context: context,
          request: fixtureRequest(),
          transitionId: 'await-approval',
          targetStatus: ServiceRequestStatus.awaitingApproval,
        ),
      );
      expect(invoker.calls.first.functionName, 'itsmTransitionWorkItem');
      expect(invoker.calls.first.payload['entityType'], 'service_request');

      await gateway.decideApproval(
        DecideServiceRequestApprovalCommand(
          context: context,
          requestId: 'request-1',
          approvalId: 'approval-1',
          decision: ApprovalDecision.reject,
          comment: 'Missing evidence',
        ),
      );
      expect(invoker.calls.last.functionName, 'itsmDecideApproval');
      final payload =
          invoker.calls.last.payload['payload']! as Map<String, Object?>;
      expect(payload['decision'], 'rejected');
      expect(payload['comment'], 'Missing evidence');
    });

    test('uses dedicated trusted operational callable envelopes', () async {
      final invoker = _RecordingInvoker(List.generate(
        4,
        (index) => {'commandId': 'command-$index'},
      ));
      final gateway = FirebaseServiceRequestCommandGateway(
        invoker,
        attachmentUploader: _RecordingUploader(),
        registrationProbe: _RegistrationProbe(const []),
      );
      final context = _context();

      await gateway.assign(
        AssignServiceRequestCommand(
          context: context,
          requestId: 'request-1',
          expectedRevision: 3,
          assignedUserId: 'manager-1',
          assignedUserName: 'Manager One',
          assignedUserEmail: 'manager@example.com',
        ),
      );
      await gateway.updateTask(
        UpdateServiceRequestTaskCommand(
          context: context,
          requestId: 'request-1',
          taskId: 'task-1',
          status: ItsmTaskStatus.completed,
          comment: 'Installed',
        ),
      );
      await gateway.addComment(
        AddServiceRequestCommentCommand(
          context: context,
          requestId: 'request-1',
          body: 'Internal progress note',
          visibility: ItsmCommentVisibility.internal,
        ),
      );
      await gateway.linkRecord(
        LinkServiceRequestRecordCommand(
          context: context,
          requestId: 'request-1',
          record: ServiceRequestLinkSummary(
            type: ServiceRequestLinkType.incident,
            recordId: 'incident-1',
            reference: 'INC-1',
            title: 'Related incident',
          ),
        ),
      );

      expect(
        invoker.calls.map((call) => call.functionName),
        [
          'itsmAssignServiceRequest',
          'itsmUpdateServiceRequestTask',
          'itsmAddServiceRequestComment',
          'itsmLinkServiceRequestRecord',
        ],
      );
      expect(
        (invoker.calls[1].payload['payload']! as Map)['status'],
        'completed',
      );
      expect(
        (invoker.calls[2].payload['payload']! as Map)['visibility'],
        'internal',
      );
      expect(
        ((invoker.calls[3].payload['payload']! as Map)['record']!
            as Map)['reference'],
        'INC-1',
      );
    });
  });

  test('controller deduplicates simultaneous submission commands', () async {
    final gateway = _DelayedGateway();
    final controller = ServiceRequestController(
      session: fixtureSession(ItsmRole.user),
      accessPolicy: const ServiceRequestAccessPolicy(),
      gateway: gateway,
    );
    final command = _createCommand();

    final first = controller.create(command: command, at: fixtureTime);
    final second = controller.create(command: command, at: fixtureTime);
    expect(controller.isExecuting(command.context.idempotencyKey), isTrue);
    gateway.complete();

    expect((await first).requestId, 'request-1');
    expect((await second).requestId, 'request-1');
    expect(gateway.calls, 1);
  });
}

CreateServiceRequestCommand _createCommand() {
  return CreateServiceRequestCommand(
    context: _context(),
    clientRequestId: 'client-request-1',
    catalogueItem: fixtureCatalogueItem(
      documents: [
        CatalogueRequiredDocument(
          key: 'proof',
          label: LocalizedValue(en: 'Proof', fr: 'Preuve'),
          allowedContentTypes: const {'application/pdf'},
        ),
      ],
    ),
    requestedFor: ServiceRequestTargetUser(
      userId: 'user-1',
      name: 'Test User',
      email: 'user@example.com',
    ),
    title: 'Unable to connect',
    description: 'Network is unavailable',
    responses: const {'title': 'Unable to connect'},
    documents: [
      ServiceRequestSubmissionDocument(
        requirementId: 'proof',
        attachmentId: 'attachment-1',
        fileName: 'proof.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List(1024),
      ),
    ],
  );
}

ItsmCommandContext _context() => ItsmCommandContext(
      idempotencyKey: 'request-command-123',
      correlationId: 'correlation-123',
      actorUserId: 'user-1',
      actorRole: ItsmRole.user,
    );

class _Invocation {
  const _Invocation(this.functionName, this.payload);

  final String functionName;
  final Map<String, Object?> payload;
}

class _RecordingInvoker implements CallableInvoker {
  _RecordingInvoker(Iterable<Object?> results)
      : _results = List<Object?>.of(results);

  final List<Object?> _results;
  final List<_Invocation> calls = [];

  @override
  Future<Object?> invoke(
      String functionName, Map<String, Object?> payload) async {
    calls.add(_Invocation(functionName, payload));
    return _results.removeAt(0);
  }
}

class _RecordingUploader implements ServiceRequestAttachmentUploader {
  _RecordingUploader({this.error});

  final Object? error;
  final List<ServiceRequestAttachmentUpload> uploads = [];

  @override
  Future<void> upload(ServiceRequestAttachmentUpload upload) async {
    uploads.add(upload);
    if (error != null) throw error!;
  }
}

class _RegistrationProbe implements ServiceRequestAttachmentRegistrationProbe {
  _RegistrationProbe(Iterable<bool> results)
      : _results = List<bool>.of(results);

  final List<bool> _results;
  var calls = 0;

  @override
  Future<bool> isRegistered({
    required String requestId,
    required String attachmentId,
  }) async {
    calls++;
    return _results.isEmpty ? false : _results.removeAt(0);
  }
}

Map<String, Object?> _draftResult() => {
      'requestId': 'request-42',
      'requestNumber': 'REQ-2026-0042',
      'status': 'draft',
      'uploadPath': 'itsm/serviceRequests/request-42/attachments',
    };

class _DelayedGateway implements ServiceRequestCommandGateway {
  final completer = Completer<ServiceRequestSubmissionReceipt>();
  var calls = 0;

  void complete() => completer.complete(
        ServiceRequestSubmissionReceipt(
          command: ItsmCommandReceipt(
            commandId: 'command-1',
            acceptedAt: fixtureTime,
            wasDuplicate: false,
          ),
          requestId: 'request-1',
          requestNumber: 'REQ-1',
          status: ServiceRequestStatus.submitted,
          workflowDefinitionId: 'standard-request',
          workflowVersion: 3,
          slaPolicyId: 'request-standard',
          slaPolicyVersion: 4,
        ),
      );

  @override
  Future<ServiceRequestSubmissionReceipt> create(
    CreateServiceRequestCommand command,
  ) {
    calls++;
    return completer.future;
  }

  @override
  Future<ItsmCommandReceipt> decideApproval(
    DecideServiceRequestApprovalCommand command,
  ) =>
      throw UnimplementedError();

  @override
  Future<ItsmCommandReceipt> transition(
    TransitionServiceRequestCommand command,
  ) =>
      throw UnimplementedError();

  @override
  Future<ItsmCommandReceipt> addComment(
    AddServiceRequestCommentCommand command,
  ) =>
      throw UnimplementedError();

  @override
  Future<ItsmCommandReceipt> assign(AssignServiceRequestCommand command) =>
      throw UnimplementedError();

  @override
  Future<ItsmCommandReceipt> linkRecord(
    LinkServiceRequestRecordCommand command,
  ) =>
      throw UnimplementedError();

  @override
  Future<ItsmCommandReceipt> updateTask(
    UpdateServiceRequestTaskCommand command,
  ) =>
      throw UnimplementedError();
}
