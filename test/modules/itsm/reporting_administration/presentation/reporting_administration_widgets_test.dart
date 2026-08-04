import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/application/reporting_administration_application.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/domain/reporting_administration_domain.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/presentation/reporting_administration_presentation.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  testWidgets('overview is responsive and marks ADMIN configuration read-only',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(
      const ReportingAdministrationOverviewScreen(),
      const ReportingAdministrationAccessState(
        role: ItsmRole.admin,
        canAccess: true,
        canOperate: false,
        isReadOnly: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Reporting & Administration'), findsOneWidget);
    expect(find.text('Dashboards'), findsOneWidget);
    expect(find.text('Read-only'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('USER receives access denied instead of reporting cards',
      (tester) async {
    await tester.pumpWidget(_app(
      const ReportingAdministrationOverviewScreen(),
      const ReportingAdministrationAccessState.denied(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Access denied'), findsOneWidget);
    expect(find.text('SLA policies'), findsNothing);
  });

  testWidgets('dashboard renders trusted metrics, breakdowns and highlights',
      (tester) async {
    await tester.pumpWidget(_responsive(MaterialApp(
        home:
            Scaffold(body: ReportingDashboardLayout(snapshot: _snapshot())))));
    await tester.pumpAndSettle();
    expect(find.text('Open Incidents'), findsOneWidget);
    expect(find.text('12'), findsWidgets);
    expect(find.text('Incidents By Priority'), findsOneWidget);
    expect(find.text('INC-1 • open'), findsOneWidget);
  });

  testWidgets('immutable workflow editor hides all mutation actions',
      (tester) async {
    final version = WorkflowVersionConfiguration.fromMap('wf-1', 'v1', {
      'version': 1,
      'status': 'published',
      'startStateId': 'open',
      'states': [
        {'id': 'open', 'label': 'Open'},
      ],
      'transitions': const [],
      'createdAt': '2026-07-01T00:00:00Z',
      'createdBy': 'manager-1',
    });
    await tester.pumpWidget(_responsive(MaterialApp(
        home: WorkflowEditorScreen(version: version, readOnly: false))));
    expect(find.text('Published versions are immutable'), findsOneWidget);
    expect(find.text('Save draft'), findsNothing);
    expect(find.text('Publish'), findsNothing);
  });

  testWidgets('SLA form emits business calendar draft values', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SlaPolicyDraftValue? submitted;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SlaPolicyForm(onSubmit: (value) => submitted = value),
        ),
      ),
    ));
    await tester.enterText(find.byType(TextFormField).at(0), 'Incident P1');
    await tester.enterText(
        find.byType(TextFormField).at(7), '2026-08-01, 2026-12-25');
    await tester.tap(find.text('Save draft'));
    await tester.pump();
    expect(submitted?.name, 'Incident P1');
    expect(submitted?.timeZone, 'Africa/Kinshasa');
    expect(submitted?.holidays, ['2026-08-01', '2026-12-25']);
    expect(submitted?.toPayload()['calendar'], isA<Map<String, Object?>>());
  });

  testWidgets('read-only catalogue form exposes no save action',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CatalogueItemForm(
            readOnly: true,
            onSubmit: (_) {},
          ),
        ),
      ),
    ));
    expect(find.text('Save draft'), findsNothing);
  });

  testWidgets('catalogue form uses one input for each localized value',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: const [Locale('en'), Locale('fr')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: CatalogueItemForm(
            readOnly: true,
            onSubmit: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Name (English)'), findsNothing);
    expect(find.text('Name (French)'), findsNothing);
  });
}

Widget _app(Widget child, ReportingAdministrationAccessState access) =>
    _responsive(
      ProviderScope(
        overrides: [
          reportingAdministrationAccessProvider
              .overrideWithValue(AsyncData(access))
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('fr')],
          localizationsDelegates: const [S.delegate],
          home: child,
        ),
      ),
    );

Widget _responsive(Widget child) => ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: 'MOBILE'),
        Breakpoint(start: 451, end: 960, name: 'TABLET'),
        Breakpoint(start: 961, end: double.infinity, name: 'DESKTOP'),
      ],
      child: child,
    );

ItsmReportSnapshot _snapshot() => ItsmReportSnapshot(
      id: 'snapshot-1',
      schemaVersion: 1,
      type: ReportSnapshotType.operational,
      audience: ItsmRole.manager,
      scopeType: 'global',
      scopeId: 'global',
      periodGranularity: 'current',
      periodKey: 'current',
      periodStart: DateTime.utc(2026, 7, 1),
      periodEnd: DateTime.utc(2026, 7, 31),
      generatedAt: DateTime.utc(2026, 7, 31),
      sourceWatermark: DateTime.utc(2026, 7, 31),
      isComplete: true,
      metrics: ReportingMetrics(
        values: const {'openIncidents': 12},
        breakdowns: const {
          'incidentsByPriority': {'P1': 2, 'P2': 4}
        },
      ),
      highlights: [
        ReportHighlight(
            id: 'incident-1',
            reference: 'INC-1',
            title: 'Mail unavailable',
            type: 'incident',
            status: 'open'),
      ],
    );
