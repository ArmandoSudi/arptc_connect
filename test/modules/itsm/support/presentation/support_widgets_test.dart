import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/widgets/support_widgets.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filter bar stacks controls on mobile', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 360,
          child: _FilterHarness(),
        ),
      ),
    );

    final search = tester.getRect(find.byType(CommonTextInput));
    final dropdown =
        tester.getRect(find.byType(DropdownButtonFormField<String>));
    expect(dropdown.top, greaterThan(search.bottom));
  });

  testWidgets('responsive grid expands to three columns', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 1000,
          child: SupportResponsiveGrid(
            minimumItemWidth: 200,
            children: List.generate(
              3,
              (index) => SizedBox(key: ValueKey(index), height: 40),
            ),
          ),
        ),
      ),
    );

    final first = tester.getRect(find.byKey(const ValueKey(0)));
    final second = tester.getRect(find.byKey(const ValueKey(1)));
    final third = tester.getRect(find.byKey(const ValueKey(2)));
    expect(first.top, second.top);
    expect(second.top, third.top);
  });

  testWidgets('status pill exposes its label to semantics', (tester) async {
    await tester.pumpWidget(
      _app(
        const SupportStatusPill(
          label: 'Awaiting approval',
          tone: SupportStatusTone.warning,
        ),
      ),
    );

    expect(find.text('Awaiting approval'), findsOneWidget);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: CorporateBlueTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

class _FilterHarness extends StatefulWidget {
  const _FilterHarness();

  @override
  State<_FilterHarness> createState() => _FilterHarnessState();
}

class _FilterHarnessState extends State<_FilterHarness> {
  String? value = 'all';

  @override
  Widget build(BuildContext context) {
    return SupportFilterBar(
      searchLabel: 'Search',
      searchHint: 'Search requests',
      onSearchChanged: (_) {},
      filters: [
        SupportDropdownFilter(
          label: 'Status',
          value: value,
          options: const [
            SupportFilterOption(value: 'all', label: 'All'),
          ],
          onChanged: (next) => setState(() => value = next),
        ),
      ],
    );
  }
}
