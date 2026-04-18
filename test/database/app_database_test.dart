import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';

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
}
