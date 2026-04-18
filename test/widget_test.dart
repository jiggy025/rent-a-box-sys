import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/main.dart';

void main() {
  testWidgets('boots the branded shell', (tester) async {
    await tester.pumpWidget(createAppRoot());

    expect(find.text('Rent-a-Box Ledger'), findsOneWidget);
  });
}
