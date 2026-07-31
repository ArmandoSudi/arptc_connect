import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/changes/presentation/widgets/change_collaboration_panel.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_audit_event.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 31, 9);

  testWidgets('manager sees operational visibility and read-only activity',
      (tester) async {
    await tester.pumpWidget(
      _app(
        ChangeCollaborationPanel(
          comments: AsyncData([
            ItsmComment(
              id: 'comment-1',
              workItemType: ItsmWorkItemType.changeRequest,
              workItemId: 'change-1',
              authorDisplayName: 'Change Manager',
              body: 'Internal implementation note',
              visibility: ItsmCommentVisibility.internal,
              createdAt: createdAt,
              createdBy: 'manager-1',
            ),
          ]),
          attachments: AsyncData([
            ItsmAttachment(
              id: 'attachment-1',
              workItemType: ItsmWorkItemType.changeRequest,
              workItemId: 'change-1',
              fileName: 'rollback-plan.pdf',
              contentType: 'application/pdf',
              sizeBytes: 2048,
              storagePath: 'itsm/changeRequests/change-1/rollback-plan.pdf',
              visibility: ItsmAttachmentVisibility.requesterVisible,
              createdAt: createdAt,
              createdBy: 'manager-1',
            ),
          ]),
          activity: AsyncData([
            ItsmAuditEvent(
              id: 'audit-1',
              actorUserId: 'manager-1',
              actorDisplayName: 'Change Manager',
              action: 'scheduled',
              targetEntityType: 'change_request',
              targetEntityId: 'change-1',
              occurredAt: createdAt,
              correlationId: 'correlation-1',
              source: 'schedule_change',
              module: 'itsm',
              fromState: 'approved',
              toState: 'scheduled',
            ),
          ]),
          showOperationalVisibility: true,
          onRetryComments: () {},
          onRetryAttachments: () {},
          onRetryActivity: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read-only access'), findsOneWidget);
    expect(find.text('Internal implementation note'), findsOneWidget);
    expect(find.text('Internal'), findsOneWidget);
    expect(find.text('Requester visible'), findsOneWidget);
    expect(find.text('approved → scheduled'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('self-service view hides visibility controls and handles states',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _app(
        ChangeCollaborationPanel(
          comments: const AsyncData([]),
          attachments: const AsyncLoading(),
          activity: AsyncError(StateError('failed'), StackTrace.empty),
          showOperationalVisibility: false,
          onRetryComments: () {},
          onRetryAttachments: () {},
          onRetryActivity: () => retries++,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No visible comments yet.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Unable to load this information.'), findsOneWidget);
    expect(find.text('Internal'), findsNothing);
    expect(find.text('Requester visible'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: const [Locale('en'), Locale('fr')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
