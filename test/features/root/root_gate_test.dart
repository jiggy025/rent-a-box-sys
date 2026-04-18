import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/root/root_gate.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void main() {
  testWidgets('shows setup when no active assignments exist', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [
          activeAssignmentCountProvider.overrideWith(
            (ref) => Stream<int>.value(0),
          ),
        ],
      ),
    );

    await pumpUntilFound(tester, find.text('Set up your first seller'));

    expect(find.text('Set up your first seller'), findsOneWidget);
  });

  testWidgets('shows dashboard when active assignments exist', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [
          activeAssignmentCountProvider.overrideWith(
            (ref) => Stream<int>.value(1),
          ),
        ],
      ),
    );

    await pumpUntilFound(tester, find.text('Dashboard'));

    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('updates from setup to dashboard when an assignment is created',
      (tester) async {
    final controller = StreamController<int>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [
          activeAssignmentCountProvider.overrideWith(
            (ref) => controller.stream,
          ),
        ],
      ),
    );

    controller.add(0);

    await pumpUntilFound(tester, find.text('Set up your first seller'));

    expect(find.text('Set up your first seller'), findsOneWidget);

    controller.add(1);

    await pumpUntilFound(tester, find.text('Dashboard'));

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
