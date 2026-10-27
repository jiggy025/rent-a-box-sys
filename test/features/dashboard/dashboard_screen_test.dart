import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/dashboard/dashboard_screen.dart';
import 'package:rent_a_box_sys/features/dashboard/widgets/box_card.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';
import 'package:rent_a_box_sys/providers/dashboard_providers.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';
import 'package:rent_a_box_sys/providers/seller_providers.dart';

import '../../helpers/test_app.dart';

Future<void> disposeTestApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.idle();
  await tester.pump();
}

void main() {
  testWidgets('renders occupied and vacant box cards and filters search', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
          dashboardBoxesProvider.overrideWith(
            (ref) => Stream.value(const [
              DashboardBoxSummary(
                boxId: 'box-01',
                boxNumber: '01',
                assignmentId: 'assign-01',
                sellerId: 'seller-01',
                sellerName: 'Mae',
                isVacant: false,
                total: 200,
              ),
              DashboardBoxSummary(
                boxId: 'box-02',
                boxNumber: '02',
                isVacant: true,
                total: 0,
              ),
            ]),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('BOX 01'), findsOneWidget);
    expect(find.text('Mae'), findsOneWidget);
    expect(find.text('Vacant'), findsWidgets);

    await tester.enterText(find.byType(TextField), '02');
    await tester.pumpAndSettle();

    expect(find.text('BOX 01'), findsNothing);
    expect(find.text('BOX 02'), findsOneWidget);

    await disposeTestApp(tester);
  });

  testWidgets('reassigns a box and resets the current total', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = StreamController<List<DashboardBoxSummary>>.broadcast();
    addTearDown(() => tester.runAsync(db.close));
    addTearDown(controller.close);
    final maeId = await db.createSeller(name: 'Mae');
    await db.createSeller(name: 'Ella');
    final sellers = await (db.select(db.sellers)).get();
    final boxId = await db.createBox(boxNumber: '01');
    final assignmentId = await db.createRentalAssignment(
      sellerId: maeId,
      boxId: boxId,
    );
    await db.addLogEntry(
      rentalAssignmentId: assignmentId,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier',
    );

    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
          databaseProvider.overrideWithValue(db),
          dashboardBoxesProvider.overrideWith((ref) => controller.stream),
          allSellersProvider.overrideWith((ref) => Stream.value(sellers)),
        ],
      ),
    );

    controller.add(const [
      DashboardBoxSummary(
        boxId: 'box-01',
        boxNumber: '01',
        assignmentId: 'assign-01',
        sellerId: 'seller-01',
        sellerName: 'Mae',
        isVacant: false,
        total: 200,
      ),
    ]);

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reassign Box'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reassign-seller-name')), findsNothing);
    expect(find.byKey(const Key('reassign-seller-dropdown')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reassign-box-number')), '01');
    await tester.tap(find.byKey(const Key('reassign-seller-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ella').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Reassignment'));
    await tester.pumpAndSettle();

    final updatedRows = await tester.runAsync(db.dashboardBoxSummaries);
    controller.add(updatedRows ?? const <DashboardBoxSummary>[]);
    await tester.pumpAndSettle();

    expect(find.text('Ella'), findsOneWidget);
    // The box card's own total resets; the dashboard summary shows a total too, so look inside the card
    expect(
      find.descendant(of: find.byType(BoxCard), matching: find.textContaining('0.00')),
      findsOneWidget,
    );

    await disposeTestApp(tester);
  });
}
