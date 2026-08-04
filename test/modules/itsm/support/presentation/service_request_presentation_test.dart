import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/approval.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/support/application/service_request_form_controller.dart';
import 'package:arptc_connect/modules/itsm/support/data/service_request_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/support/domain/support_domain.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/widgets/service_catalogue_view.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/widgets/service_request_detail_view.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/widgets/service_request_form_view.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/widgets/service_request_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support_test_fixtures.dart';

void main() {
  testWidgets('catalogue uses responsive cards and exposes search',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        ServiceCatalogueView(
          items: [fixtureCatalogueItem(), fixtureCatalogueItem(id: 'vpn')],
          languageCode: 'en',
          searchQuery: '',
          selectedCategoryId: null,
          onSearchChanged: (_) {},
          onCategorySelected: (_) {},
          onItemSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Technical assistance'), findsNWidgets(2));
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('dynamic form renders select and required documents',
      (tester) async {
    final item = fixtureCatalogueItem(
      fields: [
        CatalogueFieldSchema(
          key: 'urgency',
          type: CatalogueFieldType.singleSelect,
          label: LocalizedValue(en: 'Urgency', fr: 'Urgence'),
          options: [
            CatalogueFieldOption(
              value: 'normal',
              label: LocalizedValue(en: 'Normal', fr: 'Normale'),
            ),
          ],
        ),
      ],
      documents: [
        CatalogueRequiredDocument(
          key: 'approval',
          label: LocalizedValue(en: 'Approval letter', fr: 'Approbation'),
        ),
      ],
    );
    await tester.pumpWidget(
      _app(
        ServiceRequestFormView(
          state: ServiceRequestFormState(
            catalogueItem: item,
            requestedFor: ServiceRequestTargetUser(
              userId: 'user-1',
              name: 'Test User',
              email: 'user@example.com',
            ),
          ),
          languageCode: 'en',
          canRequestOnBehalf: false,
          agents: const [],
          agentSearchQuery: '',
          onAgentSearchChanged: (_) {},
          onAgentSelected: (_) {},
          onTitleChanged: (_) {},
          onDescriptionChanged: (_) {},
          onResponseChanged: (_, __) {},
          onPickDocument: (_) {},
          onRemoveDocument: (_) {},
          onSubmit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Urgency'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Approval letter'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Approval letter'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('request list collapses into cards on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        ServiceRequestListView(
          requests: [fixtureRequest()],
          searchQuery: '',
          onSearchChanged: (_) {},
          onSelected: (_) {},
          showRequester: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('REQ-2026-0001'), findsOneWidget);
    expect(find.text('Affected User'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager detail exposes pending approval actions',
      (tester) async {
    final detail = ServiceRequestDetail(
      request: fixtureRequest(),
      approvals: [
        ServiceRequestApprovalSummary(
          id: 'approval-1',
          step: 1,
          status: ApprovalStatus.pending,
          approverGroupId: 'line-managers',
          requestedAt: fixtureTime,
        ),
      ],
    );
    var decisions = 0;
    await tester.pumpWidget(
      _app(
        ServiceRequestDetailView(
          detail: detail,
          isManager: true,
          onApprovalDecision: (_, __) => decisions++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byIcon(Icons.check_circle_outline),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    expect(decisions, 1);
    expect(find.text('pending'), findsWidgets);
  });

  testWidgets('manager detail exposes fulfilment and task actions',
      (tester) async {
    var transitionedTo = ServiceRequestStatus.draft;
    ItsmTaskStatus? taskStatus;
    final detail = ServiceRequestDetail(
      request: fixtureRequest(status: ServiceRequestStatus.assigned),
      tasks: [
        ServiceRequestTaskSummary(
          id: 'task-1',
          title: 'Install software',
          status: ItsmTaskStatus.pending,
          createdAt: fixtureTime,
          createdByUserId: 'manager-1',
        ),
      ],
    );
    await tester.pumpWidget(
      _app(
        ServiceRequestDetailView(
          detail: detail,
          isManager: true,
          onApprovalDecision: (_, __) {},
          onTransition: (status) => transitionedTo = status,
          onTaskStatusChanged: (_, status) => taskStatus = status,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start fulfilment'));
    expect(transitionedTo, ServiceRequestStatus.inFulfilment);
    await tester.scrollUntilVisible(
      find.text('Install software'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(PopupMenuButton<ItsmTaskStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('completed').last);
    expect(taskStatus, ItsmTaskStatus.completed);
  });

  testWidgets('self-service detail exposes only valid completion action',
      (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      _app(
        ServiceRequestDetailView(
          detail: ServiceRequestDetail(
            request: fixtureRequest(status: ServiceRequestStatus.fulfilled),
          ),
          isManager: false,
          canConfirmCompletion: true,
          onApprovalDecision: (_, __) {},
          onConfirmCompletion: () => confirmed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assign'), findsNothing);
    await tester.tap(find.text('Confirm completion'));
    expect(confirmed, isTrue);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: child),
  );
}
