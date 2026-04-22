import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/dashboard/dashboard_screen.dart';
import 'package:rent_a_box_sys/models/dashboard_guide_state.dart';
import 'package:rent_a_box_sys/models/seller_adjustment_type.dart';
import 'package:rent_a_box_sys/providers/dashboard_providers.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

Future<void> disposeTestApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.idle();
  await tester.pump();
}

void expectGuideState(
  DashboardGuideState state, {
  required int sellers,
  required int activeBoxes,
  required int activeAssignments,
  required int logEntries,
  required int sellerAdjustments,
}) {
  expect(state.sellerCount, sellers);
  expect(state.activeBoxCount, activeBoxes);
  expect(state.activeAssignmentCount, activeAssignments);
  expect(state.logEntryCount, logEntries);
  expect(state.sellerAdjustmentCount, sellerAdjustments);
}

Future<void> expectNextGuideState(
  StreamIterator<DashboardGuideState> iterator, {
  required int sellers,
  required int activeBoxes,
  required int activeAssignments,
  required int logEntries,
  required int sellerAdjustments,
}) async {
  DashboardGuideState? latest;

  for (var attempt = 0; attempt < 6; attempt++) {
    expect(await iterator.moveNext(), isTrue);
    latest = iterator.current;

    if (latest.sellerCount == sellers &&
        latest.activeBoxCount == activeBoxes &&
        latest.activeAssignmentCount == activeAssignments &&
        latest.logEntryCount == logEntries &&
        latest.sellerAdjustmentCount == sellerAdjustments) {
      expectGuideState(
        latest,
        sellers: sellers,
        activeBoxes: activeBoxes,
        activeAssignments: activeAssignments,
        logEntries: logEntries,
        sellerAdjustments: sellerAdjustments,
      );
      return;
    }
  }

  fail(
    'Expected guide state '
    '(sellers: $sellers, activeBoxes: $activeBoxes, '
    'activeAssignments: $activeAssignments, logEntries: $logEntries, '
    'sellerAdjustments: $sellerAdjustments) but last state was '
    '$latest.',
  );
}

void main() {
  testWidgets('shows the setup guide card and opens branded help sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
          dashboardBoxesProvider.overrideWith((ref) => Stream.value(const [])),
          dashboardGuideStateProvider.overrideWith(
            (ref) => Stream.value(const DashboardGuideState()),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Get your dashboard ready'), findsOneWidget);
    expect(find.text('1. Add seller'), findsOneWidget);
    expect(find.text('5. Manage seller payouts'), findsOneWidget);
    expect(find.byTooltip('Help'), findsOneWidget);

    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Espasyo dashboard guide'), findsOneWidget);
    expect(find.text('3. Occupy vacant box'), findsWidgets);
    expect(find.text('4. Tap box to add sales'), findsWidgets);

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'assets/branding/espasyo.png');

    await disposeTestApp(tester);
  });

  testWidgets('shows the compact refresher card once setup is complete', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
          dashboardBoxesProvider.overrideWith((ref) => Stream.value(const [])),
          dashboardGuideStateProvider.overrideWith(
            (ref) => Stream.value(
              const DashboardGuideState(
                sellerCount: 1,
                activeBoxCount: 1,
                activeAssignmentCount: 1,
                logEntryCount: 3,
                sellerAdjustmentCount: 1,
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Need a quick refresher?'), findsOneWidget);
    expect(find.text('Dashboard setup complete'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-refresher-close')), findsOneWidget);
    expect(find.text('Get your dashboard ready'), findsNothing);
    expect(find.text('1. Add seller'), findsNothing);

    await disposeTestApp(tester);
  });

  testWidgets(
    'can dismiss the compact refresher and keep help available',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final sellerId = await db.createSeller(name: 'Mae');
      final boxId = await db.createBox(boxNumber: '01');
      await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);

      await tester.pumpWidget(
        wrapWithTestApp(
          const DashboardScreen(),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Need a quick refresher?'), findsOneWidget);
      expect(find.byTooltip('Help'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dashboard-refresher-close')));
      await tester.pumpAndSettle();

      expect(find.text('Need a quick refresher?'), findsNothing);
      expect(find.text('Dashboard setup complete'), findsNothing);
      expect(find.byTooltip('Help'), findsOneWidget);

      await disposeTestApp(tester);

      await tester.pumpWidget(
        wrapWithTestApp(
          const DashboardScreen(),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Need a quick refresher?'), findsNothing);
      expect(find.byTooltip('Help'), findsOneWidget);

      await disposeTestApp(tester);
    },
  );

  testWidgets(
    'keeps the compact refresher after setup was previously completed',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final sellerId = await db.createSeller(name: 'Mae');
      final boxId = await db.createBox(boxNumber: '01');
      await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);

      await tester.pumpWidget(
        wrapWithTestApp(
          const DashboardScreen(),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Need a quick refresher?'), findsOneWidget);
      expect(find.text('Get your dashboard ready'), findsNothing);

      await db.markSellerInactive(sellerId);
      await tester.pumpAndSettle();

      expect(find.text('Need a quick refresher?'), findsOneWidget);
      expect(find.text('Dashboard setup complete'), findsOneWidget);
      expect(find.text('Get your dashboard ready'), findsNothing);

      await disposeTestApp(tester);
    },
  );

  test('dashboard guide state reacts to database counts', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    final stateStream = StreamController<DashboardGuideState>.broadcast();
    final subscription = container.listen<AsyncValue<DashboardGuideState>>(
      dashboardGuideStateProvider,
      (previous, next) {
        next.whenData(stateStream.add);
      },
      fireImmediately: true,
    );

    addTearDown(container.dispose);
    addTearDown(db.close);
    addTearDown(subscription.close);
    addTearDown(stateStream.close);

    final iterator = StreamIterator(stateStream.stream);

    expect(await iterator.moveNext(), isTrue);
    expectGuideState(
      iterator.current,
      sellers: 0,
      activeBoxes: 0,
      activeAssignments: 0,
      logEntries: 0,
      sellerAdjustments: 0,
    );

    final sellerId = await db.createSeller(name: 'Mae');
    await expectNextGuideState(
      iterator,
      sellers: 1,
      activeBoxes: 0,
      activeAssignments: 0,
      logEntries: 0,
      sellerAdjustments: 0,
    );

    final boxId = await db.createBox(boxNumber: '01');
    await expectNextGuideState(
      iterator,
      sellers: 1,
      activeBoxes: 1,
      activeAssignments: 0,
      logEntries: 0,
      sellerAdjustments: 0,
    );

    final assignmentId = await db.createRentalAssignment(
      sellerId: sellerId,
      boxId: boxId,
    );
    await expectNextGuideState(
      iterator,
      sellers: 1,
      activeBoxes: 1,
      activeAssignments: 1,
      logEntries: 0,
      sellerAdjustments: 0,
    );

    await db.addLogEntry(
      rentalAssignmentId: assignmentId,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier',
    );
    await expectNextGuideState(
      iterator,
      sellers: 1,
      activeBoxes: 1,
      activeAssignments: 1,
      logEntries: 1,
      sellerAdjustments: 0,
    );

    await db.createSellerAdjustment(
      sellerId: sellerId,
      type: SellerAdjustmentType.cashOut,
      amount: 100,
    );
    await expectNextGuideState(
      iterator,
      sellers: 1,
      activeBoxes: 1,
      activeAssignments: 1,
      logEntries: 1,
      sellerAdjustments: 1,
    );

    await db.setDashboardRefresherDismissed(true);
    await expectNextGuideState(
      iterator,
      sellers: 1,
      activeBoxes: 1,
      activeAssignments: 1,
      logEntries: 1,
      sellerAdjustments: 1,
    );
    expect(iterator.current.isRefresherDismissed, isTrue);

    await iterator.cancel();
  });
}
