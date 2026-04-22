import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/app/app.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';
import 'package:rent_a_box_sys/providers/dashboard_providers.dart';

void main() {
  testWidgets('shows Espasyo splash before dashboard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardBoxesProvider.overrideWith(
            (ref) => Stream<List<DashboardBoxSummary>>.value(
              const <DashboardBoxSummary>[],
            ),
          ),
        ],
        child: const RentABoxApp(),
      ),
    );

    expect(find.byKey(const Key('espasyo-splash-image')), findsOneWidget);
    expect(find.byKey(const Key('espasyo-splash-loader')), findsOneWidget);
    expect(
      tester.widget<Image>(find.byKey(const Key('espasyo-splash-image'))).fit,
      BoxFit.cover,
    );
    expect(find.text('Espasyo'), findsNothing);
    expect(find.text('Preparing your dashboard'), findsNothing);
    expect(find.text('Dashboard'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1801));
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
