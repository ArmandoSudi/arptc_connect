import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_access.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_access_gate.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/user_management_section_scaffold.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserManagementAccessGate', () {
    testWidgets('denies a deep-linked private screen to a USER',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.user,
          child: const UserManagementAccessGate(
            requirePrivateProfiles: true,
            child: Text('Private organization content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Private organization content'), findsNothing);
    });

    testWidgets('allows a USER to open the safe directory surface',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.user,
          child: const UserManagementAccessGate(
            child: Text('Safe agent directory'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safe agent directory'), findsOneWidget);
      expect(find.byType(ErrorStateView), findsNothing);
    });

    testWidgets('waits for the authorized profile before building content',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.manager,
          profile: const AsyncValue.loading(),
          child: const UserManagementAccessGate(
            child: Text('Protected content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Protected content'), findsNothing);
      expect(find.byType(LoadingStateView), findsOneWidget);
    });
  });

  group('UserManagementSectionScaffold', () {
    testWidgets('shows four compact destinations and mutations to a MANAGER',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.manager,
          child: _sectionScaffold(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Create organization'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Create organization'),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('uses a four-destination rail on wide MANAGER layouts',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.manager,
          child: _sectionScaffold(),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(4));
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Create organization'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Create organization'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('limits a USER to Agents and hides mutation controls',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.user,
          child: _sectionScaffold(selectedIndex: 2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsOneWidget);
      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Organizations'), findsNothing);
      expect(find.text('Structure'), findsNothing);
      expect(find.text('Modules'), findsNothing);
      expect(find.text('Create organization'), findsNothing);
    });

    testWidgets('omits redundant wide navigation for a USER', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.user,
          child: _sectionScaffold(selectedIndex: 2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Section body'), findsOneWidget);
      expect(find.text('Create organization'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps all read destinations but no mutations for ADMIN',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _testApp(
          role: UserManagementRole.admin,
          child: _sectionScaffold(),
        ),
      );
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(4));
      expect(find.text('Create organization'), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}

Widget _sectionScaffold({int selectedIndex = 0}) {
  return UserManagementSectionScaffold(
    selectedIndex: selectedIndex,
    title: 'Organization administration',
    subtitle: 'Manage the organization hierarchy.',
    primaryAction: FilledButton(
      onPressed: () {},
      child: const Text('Create organization'),
    ),
    body: const Center(child: Text('Section body')),
  );
}

Widget _testApp({
  required UserManagementRole role,
  required Widget child,
  AsyncValue<Map<String, dynamic>> profile = const AsyncValue.data(
    <String, dynamic>{'isActive': true},
  ),
}) {
  return ProviderScope(
    overrides: [
      authorizedAgentProfileProvider.overrideWithValue(profile),
      userManagementAccessPolicyProvider.overrideWithValue(
        UserManagementAccessPolicy(role),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: child,
    ),
  );
}
