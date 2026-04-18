import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/dashboard/widgets/add_box_sheet.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('accepts digits only for box numbers', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    await tester.pumpWidget(
      wrapWithTestApp(
        const Scaffold(body: Material(child: AddBoxSheet())),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'box-A1');
    await tester.tap(find.text('Save Box'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a numeric box number.'), findsOneWidget);

    final savedBoxes = await tester.runAsync(() => db.select(db.boxes).get());
    expect(savedBoxes, isEmpty);
  });
}
