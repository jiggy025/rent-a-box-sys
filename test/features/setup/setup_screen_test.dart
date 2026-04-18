import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/setup/setup_screen.dart';
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
  testWidgets('creates first seller, box, and assignment', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    await tester.pumpWidget(
      wrapWithTestApp(
        const SetupScreen(),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.enterText(find.byKey(const Key('seller-name')), 'Mae');
    await tester.tap(find.text('Next'));
    await pumpUntilFound(tester, find.byKey(const Key('box-number')));

    await tester.enterText(find.byKey(const Key('box-number')), '01');
    await tester.tap(find.text('Next'));
    await pumpUntilFound(tester, find.text('Review your first assignment'));

    await tester.tap(find.text('Finish Setup'));
    await pumpUntilFound(tester, find.text('Dashboard'));

    expect(find.text('Dashboard'), findsOneWidget);
    final activeCount = await tester.runAsync(db.activeAssignmentCount);
    expect(activeCount, 1);
  });
}
