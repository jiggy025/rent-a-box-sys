import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/root/root_gate.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';
import 'package:rent_a_box_sys/providers/dashboard_providers.dart';
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
  testWidgets('shows setup when no ledger data exists', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [
          hasAnyLedgerDataProvider.overrideWith(
            (ref) => Stream<bool>.value(false),
          ),
          filteredDashboardBoxesProvider.overrideWith(
            (ref) => const AsyncData(<DashboardBoxSummary>[]),
          ),
        ],
      ),
    );

    await pumpUntilFound(tester, find.text('Set up your first seller'));

    expect(find.text('Set up your first seller'), findsOneWidget);
  });

  testWidgets('shows dashboard when data exists without active assignments',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [
          hasAnyLedgerDataProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          filteredDashboardBoxesProvider.overrideWith(
            (ref) => const AsyncData(<DashboardBoxSummary>[]),
          ),
        ],
      ),
    );

    await pumpUntilFound(tester, find.text('Dashboard'));

    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('updates from setup to dashboard when ledger data is created',
      (tester) async {
    final controller = StreamController<bool>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [
          hasAnyLedgerDataProvider.overrideWith(
            (ref) => controller.stream,
          ),
          filteredDashboardBoxesProvider.overrideWith(
            (ref) => const AsyncData(<DashboardBoxSummary>[]),
          ),
        ],
      ),
    );

    controller.add(false);

    await pumpUntilFound(tester, find.text('Set up your first seller'));

    expect(find.text('Set up your first seller'), findsOneWidget);

    controller.add(true);

    await pumpUntilFound(tester, find.text('Dashboard'));

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
