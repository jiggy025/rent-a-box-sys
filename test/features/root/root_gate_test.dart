import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/root/root_gate.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows setup when no active assignments exist', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Set up your first seller'), findsOneWidget);
  });

  testWidgets('shows dashboard when active assignments exist', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final sellerId = await db.createSeller(name: 'Mae');
    final boxId = await db.createBox(boxNumber: '01');
    await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);

    await tester.pumpWidget(
      wrapWithTestApp(
        const RootGate(),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
