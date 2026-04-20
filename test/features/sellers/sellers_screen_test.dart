import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/sellers/sellers_screen.dart';
import 'package:rent_a_box_sys/models/seller_ledger_summary.dart';
import 'package:rent_a_box_sys/providers/seller_providers.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('renders seller summaries and filters search', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const SellersScreen(),
        overrides: [
          sellerLedgerSummariesProvider.overrideWith(
            (ref) => Stream.value([
              SellerLedgerSummary(
                sellerId: 'seller-01',
                sellerName: 'Pej',
                isActive: true,
                activeBoxesCount: 2,
                activeBoxesTotal: 800,
                lifetimeSales: 1200,
                availableBalance: 950,
              ),
              SellerLedgerSummary(
                sellerId: 'seller-02',
                sellerName: 'Jigs',
                isActive: false,
                activeBoxesCount: 0,
                activeBoxesTotal: 0,
                lifetimeSales: 400,
                availableBalance: 300,
                inactiveAt: DateTime(2026, 4, 20),
              ),
            ]),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pej'), findsOneWidget);
    expect(find.text('Jigs'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('seller-search-field')),
      'jigs',
    );
    await tester.pumpAndSettle();

    expect(find.text('Pej'), findsNothing);
    expect(find.text('Jigs'), findsOneWidget);
  });
}
