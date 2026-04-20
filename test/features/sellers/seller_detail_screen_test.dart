import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/sellers/seller_detail_screen.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

Future<void> pumpSellerDetail(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> disposeSellerDetail(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.idle();
  await tester.pump();
}

void main() {
  testWidgets('cash out reduces available balance and adds a ledger entry',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    final sellerId = await db.createSeller(name: 'Pej');
    final boxId = await db.createBox(boxNumber: '01');
    final assignmentId = await db.createRentalAssignment(
      sellerId: sellerId,
      boxId: boxId,
    );
    await db.addLogEntry(
      rentalAssignmentId: assignmentId,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier A',
    );

    await tester.pumpWidget(
      wrapWithTestApp(
        SellerDetailScreen(sellerId: sellerId),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await pumpSellerDetail(tester);

    expect(find.byKey(const Key('seller-available-balance-value')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('seller-available-balance-value')))
          .data,
      'PHP 200.00',
    );
    expect(find.text('Active Boxes Total'), findsNothing);
    expect(find.text('Lifetime Sales'), findsOneWidget);

    await tester.tap(find.text('Cash Out'));
    await pumpSellerDetail(tester);

    await tester.enterText(
      find.byKey(const Key('seller-adjustment-amount')),
      '50',
    );
    await tester.tap(find.text('Confirm Cash Out'));
    await pumpSellerDetail(tester);

    expect(
      tester
          .widget<Text>(find.byKey(const Key('seller-available-balance-value')))
          .data,
      'PHP 150.00',
    );
    expect(find.text('Cash Out'), findsWidgets);

    await disposeSellerDetail(tester);
  });

  testWidgets('mark inactive closes active boxes for the seller', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    final sellerId = await db.createSeller(name: 'Jigs');
    final firstBoxId = await db.createBox(boxNumber: '01');
    final secondBoxId = await db.createBox(boxNumber: '02');
    await db.createRentalAssignment(sellerId: sellerId, boxId: firstBoxId);
    await db.createRentalAssignment(sellerId: sellerId, boxId: secondBoxId);

    await tester.pumpWidget(
      wrapWithTestApp(
        SellerDetailScreen(sellerId: sellerId),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await pumpSellerDetail(tester);

    await tester.tap(find.text('Mark Inactive'));
    await pumpSellerDetail(tester);
    await tester.tap(find.text('Confirm'));
    await pumpSellerDetail(tester);

    final sellerRow = await tester.runAsync(
      () => (db.select(db.sellers)..where((tbl) => tbl.id.equals(sellerId)))
          .getSingle(),
    );
    final activeBoxes = await tester.runAsync(
      () => db.activeAssignmentsForSeller(sellerId),
    );

    expect(sellerRow?.isActive, isFalse);
    expect(activeBoxes, isEmpty);

    await disposeSellerDetail(tester);
  });
}
