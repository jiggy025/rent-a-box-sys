import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/dashboard/dashboard_screen.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';
import 'package:rent_a_box_sys/providers/dashboard_providers.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('renders occupied and vacant box cards and filters search',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
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
                  total: 200,
                ),
                DashboardBoxSummary(
                  boxId: 'box-02',
                  boxNumber: '02',
                  isVacant: true,
                  total: 0,
                ),
              ],
            ),
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
  });
}
