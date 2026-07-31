import 'package:arptc_connect/modules/itsm/changes/presentation/widgets/change_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  testWidgets('change shell keeps actions usable on a narrow viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ResponsiveBreakpoints.builder(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: 'MOBILE'),
          Breakpoint(start: 451, end: 960, name: 'TABLET'),
          Breakpoint(start: 961, end: double.infinity, name: 'DESKTOP'),
        ],
        child: MaterialApp(
          home: ChangePageShell(
            title: 'Change requests',
            subtitle: 'Plan controlled service changes.',
            actions: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('New change'),
              ),
            ],
            child: const SizedBox(height: 900),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change requests'), findsOneWidget);
    expect(find.text('New change'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
