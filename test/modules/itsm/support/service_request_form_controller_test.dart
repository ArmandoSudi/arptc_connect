import 'dart:typed_data';

import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/support/application/service_request_access_policy.dart';
import 'package:arptc_connect/modules/itsm/support/application/service_request_form_controller.dart';
import 'package:arptc_connect/modules/itsm/support/data/service_request_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/support/domain/support_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support_test_fixtures.dart';

void main() {
  test('form state updates dynamic answers and builds immutable command', () {
    final controller = ServiceRequestFormController(
      ServiceRequestFormState(
        catalogueItem: fixtureCatalogueItem(),
        requestedFor: ServiceRequestTargetUser(
          userId: 'user-1',
          name: 'Test User',
          email: 'user@example.com',
        ),
      ),
    );
    controller.setTitle('Technical assistance');
    controller.setDescription('Unable to access service');
    controller.setResponse('title', 'Unable to connect');

    final command = controller.buildCommand(
      ItsmCommandContext(
        idempotencyKey: 'request-command-123',
        correlationId: 'correlation-123',
        actorUserId: 'user-1',
        actorRole: ItsmRole.user,
      ),
    );

    expect(command.responses['title'], 'Unable to connect');
    expect(command.title, 'Technical assistance');
    expect(
      controller.state
          .validate(
            principal:
                CataloguePrincipal(userId: 'user-1', role: ItsmRole.user),
            at: fixtureTime,
          )
          .isValid,
      isTrue,
    );
    expect(
      () => command.responses['title'] = 'changed',
      throwsUnsupportedError,
    );
  });

  test('required document metadata participates in catalogue validation', () {
    final item = fixtureCatalogueItem(
      documents: [
        CatalogueRequiredDocument(
          key: 'approval',
          label: LocalizedValue(en: 'Approval', fr: 'Approbation'),
          allowedContentTypes: const {'application/pdf'},
        ),
      ],
    );
    final controller = ServiceRequestFormController(
      ServiceRequestFormState(
        catalogueItem: item,
        requestedFor: ServiceRequestTargetUser(
          userId: 'user-1',
          name: 'Test User',
          email: 'user@example.com',
        ),
        responses: const {'title': 'Network issue'},
      ),
    );
    final principal = CataloguePrincipal(userId: 'user-1', role: ItsmRole.user);
    expect(
      controller.state.validate(principal: principal, at: fixtureTime).issues,
      hasLength(1),
    );

    controller.setDocuments([
      ServiceRequestSubmissionDocument(
        requirementId: 'approval',
        attachmentId: 'attachment-1',
        fileName: 'approval.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List(512),
      ),
    ]);
    expect(
      controller.state.validate(principal: principal, at: fixtureTime).isValid,
      isTrue,
    );
  });

  test('selected document validates type and maximum file count', () {
    final requirement = CatalogueRequiredDocument(
      key: 'approval',
      label: LocalizedValue(en: 'Approval', fr: 'Approbation'),
      allowedContentTypes: const {'application/pdf'},
    );
    final controller = ServiceRequestFormController(
      ServiceRequestFormState(
        catalogueItem: fixtureCatalogueItem(documents: [requirement]),
        requestedFor: ServiceRequestTargetUser(
          userId: 'user-1',
          name: 'Test User',
          email: 'user@example.com',
        ),
      ),
    );

    expect(
      () => controller.addDocument(
        requirement: requirement,
        file: ServiceRequestPickedFile(
          fileName: 'approval.png',
          contentType: 'image/png',
          bytes: Uint8List.fromList([1]),
        ),
        attachmentId: 'attachment-invalid',
      ),
      throwsA(isA<ServiceRequestValidationException>()),
    );

    controller.addDocument(
      requirement: requirement,
      file: ServiceRequestPickedFile(
        fileName: 'approval.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2]),
      ),
      attachmentId: 'attachment-1',
    );
    expect(controller.state.documents, hasLength(1));
    expect(
      () => controller.addDocument(
        requirement: requirement,
        file: ServiceRequestPickedFile(
          fileName: 'second.pdf',
          contentType: 'application/pdf',
          bytes: Uint8List.fromList([3]),
        ),
        attachmentId: 'attachment-2',
      ),
      throwsA(isA<ServiceRequestValidationException>()),
    );

    controller.removeDocument('attachment-1');
    expect(controller.state.documents, isEmpty);
  });
}
