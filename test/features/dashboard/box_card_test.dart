import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/dashboard/widgets/box_card.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';

void main() {
  testWidgets('keeps long totals on a single line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 220,
              child: BoxCard(
                summary: const DashboardBoxSummary(
                  boxId: 'box-01',
                  boxNumber: '1',
                  assignmentId: 'assignment-01',
                  sellerId: 'seller-01',
                  sellerName: 'Jigs',
                  isVacant: false,
                  total: 12345.67,
                ),
                onTap: () {},
                onSellerTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final totalText = tester.widget<Text>(find.text('PHP 12,345.67'));

    expect(totalText.maxLines, 1);
    expect(totalText.softWrap, isFalse);
  });
}
