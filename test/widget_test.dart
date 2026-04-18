import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/main.dart';

void main() {
  testWidgets('boots the application shell', (tester) async {
    await tester.pumpWidget(createAppRoot());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.title, 'Rent-a-Box Ledger');
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
