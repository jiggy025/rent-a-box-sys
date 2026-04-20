import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/models/seller_adjustment_type.dart';
import 'package:rent_a_box_sys/models/seller_transaction_record.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('seller can hold multiple active boxes', () async {
    final sellerId = await db.createSeller(name: 'Mae');
    final boxA = await db.createBox(boxNumber: '01');
    final boxB = await db.createBox(boxNumber: '02');

    await db.createRentalAssignment(sellerId: sellerId, boxId: boxA);
    await db.createRentalAssignment(sellerId: sellerId, boxId: boxB);

    final assignments = await db.activeAssignmentsForSeller(sellerId);
    expect(assignments.length, 2);
  });

  test('current box total ignores previous assignment entries', () async {
    final maeId = await db.createSeller(name: 'Mae');
    final ellaId = await db.createSeller(name: 'Ella');
    final boxId = await db.createBox(boxNumber: '01');

    final firstAssignment =
        await db.createRentalAssignment(sellerId: maeId, boxId: boxId);
    await db.addLogEntry(
      rentalAssignmentId: firstAssignment,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier A',
    );

    await db.reassignBox(boxId: boxId, nextSellerId: ellaId);
    final activeAssignment = await db.activeAssignmentForBox(boxId);
    await db.addLogEntry(
      rentalAssignmentId: activeAssignment!.id,
      itemName: 'Skirt',
      price: 90,
      claimerName: 'Cashier B',
    );

    final total = await db.currentBoxTotal(boxId);
    expect(total, 90);
  });

  test('reassigning a box closes the old assignment', () async {
    final maeId = await db.createSeller(name: 'Mae');
    final ellaId = await db.createSeller(name: 'Ella');
    final boxId = await db.createBox(boxNumber: '01');

    final original =
        await db.createRentalAssignment(sellerId: maeId, boxId: boxId);

    await db.reassignBox(boxId: boxId, nextSellerId: ellaId);

    final closed = await db.assignmentById(original);
    final active = await db.activeAssignmentForBox(boxId);

    expect(closed!.endedAt, isNotNull);
    expect(active!.sellerId, ellaId);
  });

  test('database rejects a second active assignment for the same box', () async {
    final maeId = await db.createSeller(name: 'Mae');
    final ellaId = await db.createSeller(name: 'Ella');
    final boxId = await db.createBox(boxNumber: '01');

    await db.createRentalAssignment(sellerId: maeId, boxId: boxId);

    expect(
      () => db.customStatement(
        '''
        INSERT INTO rental_assignments (id, seller_id, box_id, started_at, created_at)
        VALUES ('manual-active-assignment', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ''',
        [ellaId, boxId],
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('database rejects log entries for closed assignments', () async {
    final sellerId = await db.createSeller(name: 'Mae');
    final boxId = await db.createBox(boxNumber: '01');
    final assignmentId =
        await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);

    await db.reassignBox(
      boxId: boxId,
      nextSellerId: await db.createSeller(name: 'Ella'),
    );

    expect(
      () => db.customStatement(
        '''
        INSERT INTO log_entries (
          id,
          rental_assignment_id,
          item_name,
          price,
          claimer_name,
          timestamp
        )
        VALUES ('manual-log-entry', ?, 'Dress', 200, 'Cashier A', CURRENT_TIMESTAMP)
        ''',
        [assignmentId],
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('box numbers are unique at the schema level', () async {
    await db.createBox(boxNumber: '01');

    expect(
      () => db.createBox(boxNumber: '01'),
      throwsA(isA<Exception>()),
    );
  });

  test('seller lifetime sales survive box reassignment and return', () async {
    final pejId = await db.createSeller(name: 'Pej');
    final jigsId = await db.createSeller(name: 'Jigs');
    final boxId = await db.createBox(boxNumber: '02');

    final firstAssignment = await db.createRentalAssignment(
      sellerId: pejId,
      boxId: boxId,
    );
    await db.addLogEntry(
      rentalAssignmentId: firstAssignment,
      itemName: 'Blouse',
      price: 1000,
      claimerName: 'Cashier A',
    );

    await db.reassignBox(boxId: boxId, nextSellerId: jigsId);
    await db.reassignBox(boxId: boxId, nextSellerId: pejId);

    final currentTotal = await db.currentBoxTotal(boxId);
    final summary = await db.sellerLedgerSummary(pejId);

    expect(currentTotal, 0);
    expect(summary, isNotNull);
    expect(summary!.lifetimeSales, 1000);
    expect(summary.activeBoxesTotal, 0);
    expect(summary.availableBalance, 1000);
  });

  test('seller balance subtracts cash outs and manual deductions', () async {
    final sellerId = await db.createSeller(name: 'Mae');
    final firstBoxId = await db.createBox(boxNumber: '01');
    final secondBoxId = await db.createBox(boxNumber: '02');
    final firstAssignment = await db.createRentalAssignment(
      sellerId: sellerId,
      boxId: firstBoxId,
    );
    final secondAssignment = await db.createRentalAssignment(
      sellerId: sellerId,
      boxId: secondBoxId,
    );

    await db.addLogEntry(
      rentalAssignmentId: firstAssignment,
      itemName: 'Dress',
      price: 500,
      claimerName: 'Cashier A',
    );
    await db.addLogEntry(
      rentalAssignmentId: secondAssignment,
      itemName: 'Bag',
      price: 300,
      claimerName: 'Cashier B',
    );

    await db.createSellerAdjustment(
      sellerId: sellerId,
      type: SellerAdjustmentType.cashOut,
      amount: 200,
    );
    await db.createSellerAdjustment(
      sellerId: sellerId,
      type: SellerAdjustmentType.manualDeduction,
      amount: 50,
      reason: 'Rent',
    );

    final summary = await db.sellerLedgerSummary(sellerId);

    expect(summary, isNotNull);
    expect(summary!.lifetimeSales, 800);
    expect(summary.activeBoxesTotal, 800);
    expect(summary.availableBalance, 550);
    expect(summary.activeBoxesCount, 2);
  });

  test('marking a seller inactive vacates boxes and seller can be reused', () async {
    final sellerId = await db.createSeller(name: 'Ella');
    final firstBoxId = await db.createBox(boxNumber: '01');
    final secondBoxId = await db.createBox(boxNumber: '02');

    await db.createRentalAssignment(sellerId: sellerId, boxId: firstBoxId);
    await db.createRentalAssignment(sellerId: sellerId, boxId: secondBoxId);

    await db.markSellerInactive(sellerId);

    final sellerRow = await (db.select(
      db.sellers,
    )..where((tbl) => tbl.id.equals(sellerId))).getSingle();
    final firstBoxAssignment = await db.activeAssignmentForBox(firstBoxId);
    final secondBoxAssignment = await db.activeAssignmentForBox(secondBoxId);
    final activeAssignments = await db.activeAssignmentsForSeller(sellerId);

    expect(sellerRow.isActive, isFalse);
    expect(firstBoxAssignment, isNull);
    expect(secondBoxAssignment, isNull);
    expect(activeAssignments, isEmpty);

    final thirdBoxId = await db.createBox(boxNumber: '03');
    await db.createRentalAssignment(sellerId: sellerId, boxId: thirdBoxId);

    final reactivatedSeller = await (db.select(
      db.sellers,
    )..where((tbl) => tbl.id.equals(sellerId))).getSingle();
    final thirdBoxAssignment = await db.activeAssignmentForBox(thirdBoxId);

    expect(reactivatedSeller.isActive, isTrue);
    expect(thirdBoxAssignment, isNotNull);
    expect(thirdBoxAssignment!.sellerId, sellerId);
  });

  test('seller transaction history merges sales and deductions', () async {
    final sellerId = await db.createSeller(name: 'Jigs');
    final boxId = await db.createBox(boxNumber: '01');
    final assignmentId = await db.createRentalAssignment(
      sellerId: sellerId,
      boxId: boxId,
    );

    await db.addLogEntry(
      rentalAssignmentId: assignmentId,
      itemName: 'Toy',
      price: 150,
      claimerName: 'Cashier A',
    );
    await db.createSellerAdjustment(
      sellerId: sellerId,
      type: SellerAdjustmentType.cashOut,
      amount: 25,
    );
    await db.createSellerAdjustment(
      sellerId: sellerId,
      type: SellerAdjustmentType.manualDeduction,
      amount: 10,
      reason: 'Rent',
    );

    final transactions = await db.sellerTransactionHistory(sellerId);

    expect(transactions, hasLength(3));
    expect(transactions.where((row) => row.kind == SellerTransactionKind.sale), hasLength(1));
    expect(
      transactions.where((row) => row.kind == SellerTransactionKind.cashOut),
      hasLength(1),
    );
    expect(
      transactions.where(
        (row) => row.kind == SellerTransactionKind.manualDeduction,
      ),
      hasLength(1),
    );
    expect(transactions.first.amount.abs(), isPositive);
  });
}
