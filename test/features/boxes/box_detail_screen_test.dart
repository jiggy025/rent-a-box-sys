import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/boxes/box_detail_screen.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';
import 'package:rent_a_box_sys/providers/box_detail_providers.dart';
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
  testWidgets('adds a log entry and updates total and history', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sellerId = await db.createSeller(name: 'Mae');
    final boxId = await db.createBox(boxNumber: '01');
    final assignmentId =
        await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);
    final assignment = await db.activeAssignmentForBox(boxId);
    final entriesController = StreamController<List<LogEntry>>.broadcast();
    final totalController = StreamController<double>.broadcast();

    addTearDown(() => tester.runAsync(db.close));
    addTearDown(entriesController.close);
    addTearDown(totalController.close);

    await tester.pumpWidget(
      wrapWithTestApp(
        BoxDetailScreen(boxId: boxId),
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeAssignmentForBoxProvider(boxId).overrideWith(
            (ref) => Future.value(assignment),
          ),
          assignmentEntriesProvider(assignmentId).overrideWith(
            (ref) => entriesController.stream,
          ),
          assignmentTotalProvider(assignmentId).overrideWith(
            (ref) => totalController.stream,
          ),
          dashboardBoxesProvider.overrideWith(
            (ref) => Stream.value(
              const [
                DashboardBoxSummary(
                  boxId: 'box-01',
                  boxNumber: '01',
                  assignmentId: 'assign-01',
                  sellerId: 'seller-01',
                  sellerName: 'Mae',
                  isVacant: false,
                  total: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    entriesController.add(const []);
    totalController.add(0);
    await pumpUntilFound(tester, find.text('Add Entry'));

    await tester.enterText(find.byKey(const Key('item-name')), 'Dress');
    await tester.enterText(find.byKey(const Key('item-price')), '250');
    await tester.enterText(find.byKey(const Key('claimer-name')), 'Cashier A');
    await tester.tap(find.text('Add Entry'));
    await tester.pump();

    final entries = await tester.runAsync(
      () => (db.select(db.logEntries)
            ..where((tbl) => tbl.rentalAssignmentId.equals(assignmentId)))
          .get(),
    );
    final total = await tester.runAsync(() => db.currentBoxTotal(boxId));

    entriesController.add(entries ?? const <LogEntry>[]);
    totalController.add(total ?? 0);
    await pumpUntilFound(tester, find.text('Dress'));

    expect(find.text('Dress'), findsOneWidget);
    expect(find.text('₱ 250.00'), findsWidgets);
  });
}
