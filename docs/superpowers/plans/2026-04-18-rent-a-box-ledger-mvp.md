# Rent-a-Box Ledger MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved Android-first, offline Flutter ledger app with seller records, box records, rental assignments, rapid sales entry, a box-style dashboard, and seller history.

**Architecture:** Create a Flutter Android app rooted in a `ProviderScope`, store all domain data in Drift/SQLite, and model current totals around `rental_assignments` instead of raw box ownership. Use a root gate to switch between first-launch setup and the dashboard, then layer in dashboard cards, admin sheets, box detail entry, and seller history.

**Tech Stack:** Flutter, Dart, flutter_riverpod, Drift, SQLite, Material 3, google_fonts, intl, uuid

---

### Task 1: Bootstrap The Flutter App And Branded Shell

**Files:**
- Create: Flutter-generated Android project files in `D:\rent-a-box-sys\`
- Create: `lib/app/app.dart`
- Create: `lib/app/app_theme.dart`
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Scaffold the project and initialize git**

Run:

```bash
flutter create --platforms=android --project-name rent_a_box_sys --org com.rentabox.ledger .
git init
```

Expected:
- Flutter creates the Android project in `D:\rent-a-box-sys`
- `pubspec.yaml`, `lib/`, `android/`, and `test/` now exist
- `git status` shows an uncommitted new project

- [ ] **Step 2: Add the approved dependencies**

Update `pubspec.yaml` dependencies to:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.5.1
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.2
  path: ^1.9.0
  uuid: ^4.3.3
  intl: ^0.19.0
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  drift_dev: ^2.16.0
  build_runner: ^2.4.8
```

Run:

```bash
flutter pub get
```

Expected:
- Pub resolves successfully
- `pubspec.lock` is created or updated

- [ ] **Step 3: Write the failing shell smoke test**

Replace `test/widget_test.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/app/app.dart';

void main() {
  testWidgets('boots the branded shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RentABoxApp()));

    expect(find.text('Rent-a-Box Ledger'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run the smoke test and verify it fails**

Run:

```bash
flutter test test/widget_test.dart
```

Expected:
- FAIL with an import or missing-class error for `RentABoxApp`

- [ ] **Step 5: Implement the branded app shell**

Create `lib/app/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.dmSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB97A37),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F1E8),
    textTheme: textTheme,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
```

Create `lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_theme.dart';

class RentABoxApp extends StatelessWidget {
  const RentABoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent-a-Box Ledger',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Text('Rent-a-Box Ledger'),
        ),
      ),
    );
  }
}
```

Update `lib/main.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RentABoxApp()));
}
```

- [ ] **Step 6: Run the smoke test and verify it passes**

Run:

```bash
flutter test test/widget_test.dart
```

Expected:
- PASS

- [ ] **Step 7: Commit the bootstrap**

Run:

```bash
git add .
git commit -m "chore: bootstrap flutter ledger shell"
```

### Task 2: Implement The Drift Schema And Assignment Logic

**Files:**
- Create: `lib/database/app_database.dart`
- Create: `lib/models/dashboard_box_summary.dart`
- Create: `lib/models/seller_history_record.dart`
- Modify: `pubspec.yaml`
- Test: `test/database/app_database_test.dart`

- [ ] **Step 1: Write failing database tests for seller reuse, assignment totals, and box reassignment**

Create `test/database/app_database_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('seller can hold multiple active boxes', () async {
    final sellerId = await db.createSeller(name: 'Mae');
    final boxA = await db.createBox(boxNumber: '01');
    final boxB = await db.createBox(boxNumber: '02');

    await db.createRentalAssignment(sellerId: sellerId, boxId: boxA);
    await db.createRentalAssignment(sellerId: sellerId, boxId: boxB);

    final assignments = await db.activeAssignmentsForSeller(sellerId);
    expect(assignments.length, 2);
  });

  test('current box total ignores previous assignment entries', () async {
    final maeId = await db.createSeller(name: 'Mae');
    final ellaId = await db.createSeller(name: 'Ella');
    final boxId = await db.createBox(boxNumber: '01');

    final firstAssignment =
        await db.createRentalAssignment(sellerId: maeId, boxId: boxId);
    await db.addLogEntry(
      rentalAssignmentId: firstAssignment,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier A',
    );

    await db.reassignBox(boxId: boxId, nextSellerId: ellaId);
    final activeAssignment = await db.activeAssignmentForBox(boxId);
    await db.addLogEntry(
      rentalAssignmentId: activeAssignment!.id,
      itemName: 'Skirt',
      price: 90,
      claimerName: 'Cashier B',
    );

    final total = await db.currentBoxTotal(boxId);
    expect(total, 90);
  });

  test('reassigning a box closes the old assignment', () async {
    final maeId = await db.createSeller(name: 'Mae');
    final ellaId = await db.createSeller(name: 'Ella');
    final boxId = await db.createBox(boxNumber: '01');

    final original =
        await db.createRentalAssignment(sellerId: maeId, boxId: boxId);

    await db.reassignBox(boxId: boxId, nextSellerId: ellaId);

    final closed = await db.assignmentById(original);
    final active = await db.activeAssignmentForBox(boxId);

    expect(closed!.endedAt, isNotNull);
    expect(active!.sellerId, ellaId);
  });
}
```

- [ ] **Step 2: Run the database tests and verify they fail**

Run:

```bash
flutter test test/database/app_database_test.dart
```

Expected:
- FAIL because `AppDatabase` methods and models do not exist yet

- [ ] **Step 3: Add the DTOs used by dashboard and seller history queries**

Create `lib/models/dashboard_box_summary.dart`:

```dart
class DashboardBoxSummary {
  const DashboardBoxSummary({
    required this.boxId,
    required this.boxNumber,
    required this.isVacant,
    required this.total,
    this.assignmentId,
    this.sellerId,
    this.sellerName,
  });

  final String boxId;
  final String boxNumber;
  final String? assignmentId;
  final String? sellerId;
  final String? sellerName;
  final bool isVacant;
  final double total;
}
```

Create `lib/models/seller_history_record.dart`:

```dart
class SellerHistoryRecord {
  const SellerHistoryRecord({
    required this.assignmentId,
    required this.boxNumber,
    required this.startedAt,
    required this.endedAt,
    required this.total,
    required this.isActive,
  });

  final String assignmentId;
  final String boxNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double total;
  final bool isActive;
}
```

- [ ] **Step 4: Implement the Drift database, tables, and core methods**

Create `lib/database/app_database.dart`:

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/dashboard_box_summary.dart';
import '../models/seller_history_record.dart';

part 'app_database.g.dart';

class Sellers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get contactInfo => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Boxes extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get boxNumber => text().withLength(min: 1, max: 20)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class RentalAssignments extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get sellerId => text().references(Sellers, #id)();
  TextColumn get boxId => text().references(Boxes, #id)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class LogEntries extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get rentalAssignmentId =>
      text().references(RentalAssignments, #id)();
  TextColumn get itemName => text().withLength(min: 1, max: 120)();
  RealColumn get price => real()();
  TextColumn get claimerName => text().withLength(min: 1, max: 80)();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(
  tables: [Sellers, Boxes, RentalAssignments, LogEntries],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  Future<String> createSeller({
    required String name,
    String? contactInfo,
  }) async {
    return into(sellers).insertReturning(
      SellersCompanion.insert(
        name: name,
        contactInfo: Value(contactInfo),
      ),
    ).then((row) => row.id);
  }

  Future<String> createBox({required String boxNumber}) async {
    return into(boxes).insertReturning(
      BoxesCompanion.insert(boxNumber: boxNumber),
    ).then((row) => row.id);
  }

  Future<String> createRentalAssignment({
    required String sellerId,
    required String boxId,
  }) async {
    final active = await activeAssignmentForBox(boxId);
    if (active != null) {
      throw StateError('Box already has an active assignment.');
    }

    return into(rentalAssignments).insertReturning(
      RentalAssignmentsCompanion.insert(
        sellerId: sellerId,
        boxId: boxId,
      ),
    ).then((row) => row.id);
  }

  Future<void> addLogEntry({
    required String rentalAssignmentId,
    required String itemName,
    required double price,
    required String claimerName,
  }) {
    return into(logEntries).insert(
      LogEntriesCompanion.insert(
        rentalAssignmentId: rentalAssignmentId,
        itemName: itemName,
        price: price,
        claimerName: claimerName,
      ),
    );
  }

  Future<void> reassignBox({
    required String boxId,
    required String nextSellerId,
  }) {
    return transaction(() async {
      final active = await activeAssignmentForBox(boxId);
      if (active != null) {
        await (update(rentalAssignments)
              ..where((tbl) => tbl.id.equals(active.id)))
            .write(
          RentalAssignmentsCompanion(
            endedAt: Value(DateTime.now()),
          ),
        );
      }

      await createRentalAssignment(sellerId: nextSellerId, boxId: boxId);
    });
  }

  Future<int> activeAssignmentCount() async {
    final query = selectOnly(rentalAssignments)
      ..addColumns([rentalAssignments.id.count()])
      ..where(rentalAssignments.endedAt.isNull());
    final row = await query.getSingle();
    return row.read(rentalAssignments.id.count()) ?? 0;
  }

  Future<List<RentalAssignment>> activeAssignmentsForSeller(String sellerId) {
    return (select(rentalAssignments)
          ..where((tbl) => tbl.sellerId.equals(sellerId) & tbl.endedAt.isNull()))
        .get();
  }

  Future<RentalAssignment?> activeAssignmentForBox(String boxId) {
    return (select(rentalAssignments)
          ..where((tbl) => tbl.boxId.equals(boxId) & tbl.endedAt.isNull()))
        .getSingleOrNull();
  }

  Future<RentalAssignment?> assignmentById(String assignmentId) {
    return (select(rentalAssignments)
          ..where((tbl) => tbl.id.equals(assignmentId)))
        .getSingleOrNull();
  }

  Future<double> currentBoxTotal(String boxId) async {
    final active = await activeAssignmentForBox(boxId);
    if (active == null) return 0;

    final query = selectOnly(logEntries)
      ..addColumns([logEntries.price.sum()])
      ..where(logEntries.rentalAssignmentId.equals(active.id));

    final row = await query.getSingle();
    return row.read(logEntries.price.sum()) ?? 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'rent_a_box_ledger.sqlite'));
    return NativeDatabase(file);
  });
}
```

- [ ] **Step 5: Generate the Drift code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected:
- `lib/database/app_database.g.dart` is generated

- [ ] **Step 6: Run the database tests and verify they pass**

Run:

```bash
flutter test test/database/app_database_test.dart
```

Expected:
- PASS for all three tests

- [ ] **Step 7: Commit the database layer**

Run:

```bash
git add lib/database lib/models test/database pubspec.*
git commit -m "feat: add drift schema and assignment logic"
```

### Task 3: Add Providers And The Root Gate

**Files:**
- Create: `lib/providers/database_provider.dart`
- Create: `lib/features/root/root_gate.dart`
- Modify: `lib/app/app.dart`
- Create: `lib/features/setup/setup_screen.dart`
- Create: `lib/features/dashboard/dashboard_screen.dart`
- Create: `test/helpers/test_app.dart`
- Create: `test/features/root/root_gate_test.dart`
- Test: `test/features/root/root_gate_test.dart`

- [ ] **Step 1: Write failing widget tests for startup routing**

Create `test/helpers/test_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget wrapWithTestApp(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}
```

Create `test/features/root/root_gate_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/root/root_gate.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows setup when no active assignments exist', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

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
```

- [ ] **Step 2: Run the root gate tests and verify they fail**

Run:

```bash
flutter test test/features/root/root_gate_test.dart
```

Expected:
- FAIL because providers and root gate do not exist yet

- [ ] **Step 3: Implement the providers and placeholder setup/dashboard screens**

Create `lib/providers/database_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final activeAssignmentCountProvider = FutureProvider<int>((ref) {
  return ref.watch(databaseProvider).activeAssignmentCount();
});
```

Create `lib/features/setup/setup_screen.dart`:

```dart
import 'package:flutter/material.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Set up your first seller'),
      ),
    );
  }
}
```

Create `lib/features/dashboard/dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Dashboard'),
      ),
    );
  }
}
```

Create `lib/features/root/root_gate.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../setup/setup_screen.dart';

class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(activeAssignmentCountProvider);

    return activeCount.when(
      data: (count) => count == 0
          ? const SetupScreen()
          : const DashboardScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text(error.toString())),
      ),
    );
  }
}
```

Update `lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';

import '../features/root/root_gate.dart';
import 'app_theme.dart';

class RentABoxApp extends StatelessWidget {
  const RentABoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent-a-Box Ledger',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootGate(),
    );
  }
}
```

- [ ] **Step 4: Run the root gate tests and verify they pass**

Run:

```bash
flutter test test/features/root/root_gate_test.dart
```

Expected:
- PASS

- [ ] **Step 5: Commit the root routing layer**

Run:

```bash
git add lib/providers lib/features/root lib/features/setup lib/features/dashboard test/features/root test/helpers lib/app/app.dart
git commit -m "feat: add startup gate and core providers"
```

### Task 4: Implement The First-Launch Setup Flow

**Files:**
- Modify: `lib/features/setup/setup_screen.dart`
- Modify: `lib/providers/database_provider.dart`
- Create: `test/features/setup/setup_screen_test.dart`
- Test: `test/features/setup/setup_screen_test.dart`

- [ ] **Step 1: Write the failing setup-flow widget test**

Create `test/features/setup/setup_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/setup/setup_screen.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('creates first seller, box, and assignment', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      wrapWithTestApp(
        const SetupScreen(),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.enterText(find.byKey(const Key('seller-name')), 'Mae');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('box-number')), '01');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(await db.activeAssignmentCount(), 1);
  });
}
```

- [ ] **Step 2: Run the setup-flow test and verify it fails**

Run:

```bash
flutter test test/features/setup/setup_screen_test.dart
```

Expected:
- FAIL because the setup UI does not expose the fields and buttons yet

- [ ] **Step 3: Add a refresh provider and implement the three-step setup screen**

Append to `lib/providers/database_provider.dart`:

```dart
final refreshTickProvider = StateProvider<int>((ref) => 0);
```

Replace `lib/features/setup/setup_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../dashboard/dashboard_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _sellerController = TextEditingController();
  final _boxController = TextEditingController();
  int _step = 0;
  bool _saving = false;

  @override
  void dispose() {
    _sellerController.dispose();
    _boxController.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    final sellerId = await db.createSeller(name: _sellerController.text.trim());
    final boxId = await db.createBox(boxNumber: _boxController.text.trim());
    await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);

    ref.read(refreshTickProvider.notifier).state++;

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      0 => 'Set up your first seller',
      1 => 'Create your first box',
      _ => 'Review your first assignment',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('First Launch Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            if (_step == 0)
              TextField(
                key: const Key('seller-name'),
                controller: _sellerController,
                decoration: const InputDecoration(labelText: 'Seller name'),
              ),
            if (_step == 1)
              TextField(
                key: const Key('box-number'),
                controller: _boxController,
                decoration: const InputDecoration(labelText: 'Box number'),
              ),
            if (_step == 2)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seller: ${_sellerController.text}'),
                      const SizedBox(height: 8),
                      Text('Box: ${_boxController.text}'),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_step < 2) {
                        setState(() => _step += 1);
                      } else {
                        _finishSetup();
                      }
                    },
              child: Text(_step < 2 ? 'Next' : 'Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the setup-flow test and verify it passes**

Run:

```bash
flutter test test/features/setup/setup_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 5: Commit the setup flow**

Run:

```bash
git add lib/features/setup lib/providers/database_provider.dart test/features/setup
git commit -m "feat: add first-launch setup flow"
```

### Task 5: Build The Dashboard Query, Search, And Modern Box Cards

**Files:**
- Modify: `lib/database/app_database.dart`
- Create: `lib/providers/dashboard_providers.dart`
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Create: `lib/features/dashboard/widgets/box_card.dart`
- Create: `test/features/dashboard/dashboard_screen_test.dart`
- Test: `test/features/dashboard/dashboard_screen_test.dart`

- [ ] **Step 1: Write the failing dashboard widget test**

Create `test/features/dashboard/dashboard_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/dashboard/dashboard_screen.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('renders occupied and vacant box cards and filters search',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sellerId = await db.createSeller(name: 'Mae');
    final box01 = await db.createBox(boxNumber: '01');
    await db.createBox(boxNumber: '02');
    final assignmentId =
        await db.createRentalAssignment(sellerId: sellerId, boxId: box01);
    await db.addLogEntry(
      rentalAssignmentId: assignmentId,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier',
    );

    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('BOX 01'), findsOneWidget);
    expect(find.text('Mae'), findsOneWidget);
    expect(find.text('Vacant'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '02');
    await tester.pumpAndSettle();

    expect(find.text('BOX 01'), findsNothing);
    expect(find.text('BOX 02'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the dashboard test and verify it fails**

Run:

```bash
flutter test test/features/dashboard/dashboard_screen_test.dart
```

Expected:
- FAIL because the dashboard is still a placeholder

- [ ] **Step 3: Implement the dashboard query providers**

Append query methods to `lib/database/app_database.dart`:

```dart
  Stream<List<DashboardBoxSummary>> watchDashboardBoxes() {
    return customSelect(
      '''
      SELECT
        b.id AS box_id,
        b.box_number,
        ra.id AS assignment_id,
        s.id AS seller_id,
        s.name AS seller_name,
        CASE WHEN ra.id IS NULL THEN 1 ELSE 0 END AS is_vacant,
        COALESCE(
          (
            SELECT SUM(le.price)
            FROM log_entries le
            WHERE le.rental_assignment_id = ra.id
          ),
          0
        ) AS total
      FROM boxes b
      LEFT JOIN rental_assignments ra
        ON ra.box_id = b.id
       AND ra.ended_at IS NULL
      LEFT JOIN sellers s
        ON s.id = ra.seller_id
      ORDER BY b.box_number
      ''',
      readsFrom: {boxes, rentalAssignments, sellers, logEntries},
    ).watch().map((rows) {
      return rows.map((row) {
        return DashboardBoxSummary(
          boxId: row.read<String>('box_id'),
          boxNumber: row.read<String>('box_number'),
          assignmentId: row.read<String?>('assignment_id'),
          sellerId: row.read<String?>('seller_id'),
          sellerName: row.read<String?>('seller_name'),
          isVacant: row.read<int>('is_vacant') == 1,
          total: row.read<double>('total'),
        );
      }).toList();
    });
  }
```

Create `lib/providers/dashboard_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_box_summary.dart';
import 'database_provider.dart';

final dashboardSearchProvider = StateProvider<String>((ref) => '');

final dashboardBoxesProvider = StreamProvider<List<DashboardBoxSummary>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(databaseProvider).watchDashboardBoxes();
});

final filteredDashboardBoxesProvider =
    Provider<AsyncValue<List<DashboardBoxSummary>>>((ref) {
  final query = ref.watch(dashboardSearchProvider).trim().toLowerCase();
  final boxes = ref.watch(dashboardBoxesProvider);

  return boxes.whenData((rows) {
    if (query.isEmpty) return rows;

    return rows.where((row) {
      return row.boxNumber.toLowerCase().contains(query) ||
          (row.sellerName?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});
```

- [ ] **Step 4: Implement the modern box-card widget and dashboard screen**

Create `lib/features/dashboard/widgets/box_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';

class BoxCard extends StatelessWidget {
  const BoxCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onSellerTap,
  });

  final DashboardBoxSummary summary;
  final VoidCallback onTap;
  final VoidCallback onSellerTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFCF7), Color(0xFFF1E5D4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFD9C3A2)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Transform.rotate(
                angle: 0.7,
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFE4B171),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOX ${summary.boxNumber}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(summary.isVacant ? 'Vacant' : 'Occupied'),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: summary.sellerId == null ? null : onSellerTap,
                  child: Text(
                    summary.sellerName ?? 'Vacant',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(summary.total),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

Replace `lib/features/dashboard/dashboard_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import 'widgets/box_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardBoxes = ref.watch(filteredDashboardBoxesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search box or seller',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(dashboardSearchProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: dashboardBoxes.when(
                data: (rows) => GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final summary = rows[index];
                    return BoxCard(
                      summary: summary,
                      onTap: () {},
                      onSellerTap: () {},
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the dashboard test and verify it passes**

Run:

```bash
flutter test test/features/dashboard/dashboard_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 6: Commit the dashboard card UI**

Run:

```bash
git add lib/features/dashboard lib/providers/dashboard_providers.dart lib/database/app_database.dart test/features/dashboard
git commit -m "feat: add searchable box dashboard"
```

### Task 6: Add Dashboard Actions For Seller Creation, Box Creation, And Reassignment

**Files:**
- Modify: `lib/database/app_database.dart`
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Create: `lib/features/dashboard/widgets/dashboard_actions_sheet.dart`
- Create: `lib/features/dashboard/widgets/add_seller_sheet.dart`
- Create: `lib/features/dashboard/widgets/add_box_sheet.dart`
- Create: `lib/features/dashboard/widgets/reassign_box_sheet.dart`
- Modify: `test/features/dashboard/dashboard_screen_test.dart`
- Test: `test/features/dashboard/dashboard_screen_test.dart`

- [ ] **Step 1: Extend the dashboard test with action-sheet coverage**

Append this test to `test/features/dashboard/dashboard_screen_test.dart`:

```dart
  testWidgets('reassigns a box and resets the current total', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final maeId = await db.createSeller(name: 'Mae');
    final ellaId = await db.createSeller(name: 'Ella');
    final boxId = await db.createBox(boxNumber: '01');
    final assignmentId =
        await db.createRentalAssignment(sellerId: maeId, boxId: boxId);
    await db.addLogEntry(
      rentalAssignmentId: assignmentId,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier',
    );

    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reassign Box'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('reassign-box-number')), '01');
    await tester.enterText(find.byKey(const Key('reassign-seller-name')), 'Ella');
    await tester.tap(find.text('Confirm Reassignment'));
    await tester.pumpAndSettle();

    expect(find.text('Ella'), findsOneWidget);
    expect(find.text('₱ 0.00'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the dashboard suite and verify the new test fails**

Run:

```bash
flutter test test/features/dashboard/dashboard_screen_test.dart
```

Expected:
- FAIL because the action sheet and reassignment flow do not exist yet

- [ ] **Step 3: Implement the action sheet and forms**

Create `lib/features/dashboard/widgets/dashboard_actions_sheet.dart`:

```dart
import 'package:flutter/material.dart';

class DashboardActionsSheet extends StatelessWidget {
  const DashboardActionsSheet({
    super.key,
    required this.onAddSeller,
    required this.onAddBox,
    required this.onReassign,
  });

  final VoidCallback onAddSeller;
  final VoidCallback onAddBox;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text('Add Seller'),
            onTap: onAddSeller,
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('Add Box'),
            onTap: onAddBox,
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Reassign Box'),
            onTap: onReassign,
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/dashboard/widgets/add_seller_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';

class AddSellerSheet extends ConsumerStatefulWidget {
  const AddSellerSheet({super.key});

  @override
  ConsumerState<AddSellerSheet> createState() => _AddSellerSheetState();
}

class _AddSellerSheetState extends ConsumerState<AddSellerSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(databaseProvider).createSeller(name: _nameController.text.trim());
    ref.read(refreshTickProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Seller name'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save Seller')),
        ],
      ),
    );
  }
}
```

Create `lib/features/dashboard/widgets/add_box_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';

class AddBoxSheet extends ConsumerStatefulWidget {
  const AddBoxSheet({super.key});

  @override
  ConsumerState<AddBoxSheet> createState() => _AddBoxSheetState();
}

class _AddBoxSheetState extends ConsumerState<AddBoxSheet> {
  final _boxController = TextEditingController();

  @override
  void dispose() {
    _boxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(databaseProvider).createBox(boxNumber: _boxController.text.trim());
    ref.read(refreshTickProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _boxController,
            decoration: const InputDecoration(labelText: 'Box number'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save Box')),
        ],
      ),
    );
  }
}
```

Create `lib/features/dashboard/widgets/reassign_box_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';

class ReassignBoxSheet extends ConsumerStatefulWidget {
  const ReassignBoxSheet({super.key});

  @override
  ConsumerState<ReassignBoxSheet> createState() => _ReassignBoxSheetState();
}

class _ReassignBoxSheetState extends ConsumerState<ReassignBoxSheet> {
  final _boxNumberController = TextEditingController();
  final _sellerNameController = TextEditingController();

  @override
  void dispose() {
    _boxNumberController.dispose();
    _sellerNameController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final db = ref.read(databaseProvider);
    final box = await (db.select(db.boxes)
          ..where((tbl) => tbl.boxNumber.equals(_boxNumberController.text.trim())))
        .getSingle();

    final sellerRows = await (db.select(db.sellers)
          ..where((tbl) => tbl.name.equals(_sellerNameController.text.trim())))
        .get();

    final sellerId = sellerRows.isEmpty
        ? await db.createSeller(name: _sellerNameController.text.trim())
        : sellerRows.single.id;

    await db.reassignBox(boxId: box.id, nextSellerId: sellerId);
    ref.read(refreshTickProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('reassign-box-number'),
            controller: _boxNumberController,
            decoration: const InputDecoration(labelText: 'Box number'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reassign-seller-name'),
            controller: _sellerNameController,
            decoration: const InputDecoration(labelText: 'Seller name'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _confirm,
            child: const Text('Confirm Reassignment'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the action sheet into the dashboard**

Update `lib/features/dashboard/dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import 'widgets/add_box_sheet.dart';
import 'widgets/add_seller_sheet.dart';
import 'widgets/box_card.dart';
import 'widgets/dashboard_actions_sheet.dart';
import 'widgets/reassign_box_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardBoxes = ref.watch(filteredDashboardBoxesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openSheet(
            context,
            DashboardActionsSheet(
              onAddSeller: () {
                Navigator.of(context).pop();
                _openSheet(context, const AddSellerSheet());
              },
              onAddBox: () {
                Navigator.of(context).pop();
                _openSheet(context, const AddBoxSheet());
              },
              onReassign: () {
                Navigator.of(context).pop();
                _openSheet(context, const ReassignBoxSheet());
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search box or seller',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(dashboardSearchProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: dashboardBoxes.when(
                data: (rows) => GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final summary = rows[index];
                    return BoxCard(
                      summary: summary,
                      onTap: () {},
                      onSellerTap: () {},
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the dashboard suite and verify it passes**

Run:

```bash
flutter test test/features/dashboard/dashboard_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 6: Commit the dashboard action flows**

Run:

```bash
git add lib/features/dashboard lib/database/app_database.dart test/features/dashboard
git commit -m "feat: add dashboard management actions"
```

### Task 7: Implement The Box Detail Rapid-Entry Screen

**Files:**
- Modify: `lib/database/app_database.dart`
- Create: `lib/providers/box_detail_providers.dart`
- Create: `lib/features/boxes/box_detail_screen.dart`
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Create: `test/features/boxes/box_detail_screen_test.dart`
- Test: `test/features/boxes/box_detail_screen_test.dart`

- [ ] **Step 1: Write the failing box-detail widget test**

Create `test/features/boxes/box_detail_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/boxes/box_detail_screen.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('adds a log entry and updates total and history', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sellerId = await db.createSeller(name: 'Mae');
    final boxId = await db.createBox(boxNumber: '01');
    await db.createRentalAssignment(sellerId: sellerId, boxId: boxId);

    await tester.pumpWidget(
      wrapWithTestApp(
        BoxDetailScreen(boxId: boxId),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('item-name')), 'Dress');
    await tester.enterText(find.byKey(const Key('item-price')), '250');
    await tester.enterText(find.byKey(const Key('claimer-name')), 'Cashier A');
    await tester.tap(find.text('Add Entry'));
    await tester.pumpAndSettle();

    expect(find.text('Dress'), findsOneWidget);
    expect(find.text('₱ 250.00'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run the box-detail test and verify it fails**

Run:

```bash
flutter test test/features/boxes/box_detail_screen_test.dart
```

Expected:
- FAIL because the detail screen and providers do not exist yet

- [ ] **Step 3: Add assignment-scoped entry watchers**

Append to `lib/database/app_database.dart`:

```dart
  Stream<List<LogEntry>> watchEntriesForAssignment(String assignmentId) {
    return (select(logEntries)
          ..where((tbl) => tbl.rentalAssignmentId.equals(assignmentId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .watch();
  }

  Stream<double> watchAssignmentTotal(String assignmentId) {
    final query = selectOnly(logEntries)
      ..addColumns([logEntries.price.sum()])
      ..where(logEntries.rentalAssignmentId.equals(assignmentId));

    return query.map((row) => row.read(logEntries.price.sum()) ?? 0).watchSingle();
  }
```

Create `lib/providers/box_detail_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';

final activeAssignmentForBoxProvider =
    FutureProvider.family((ref, String boxId) {
  return ref.watch(databaseProvider).activeAssignmentForBox(boxId);
});

final assignmentEntriesProvider =
    StreamProvider.family((ref, String assignmentId) {
  return ref.watch(databaseProvider).watchEntriesForAssignment(assignmentId);
});

final assignmentTotalProvider =
    StreamProvider.family((ref, String assignmentId) {
  return ref.watch(databaseProvider).watchAssignmentTotal(assignmentId);
});
```

- [ ] **Step 4: Implement the detail screen and connect box-card navigation**

Create `lib/features/boxes/box_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard_box_summary.dart';
import '../../providers/box_detail_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/database_provider.dart';

class BoxDetailScreen extends ConsumerStatefulWidget {
  const BoxDetailScreen({super.key, required this.boxId});

  final String boxId;

  @override
  ConsumerState<BoxDetailScreen> createState() => _BoxDetailScreenState();
}

class _BoxDetailScreenState extends ConsumerState<BoxDetailScreen> {
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _claimerController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _claimerController.dispose();
    super.dispose();
  }

  Future<void> _submit(String assignmentId) async {
    await ref.read(databaseProvider).addLogEntry(
          rentalAssignmentId: assignmentId,
          itemName: _itemController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          claimerName: _claimerController.text.trim(),
        );

    _itemController.clear();
    _priceController.clear();
    _claimerController.clear();
    ref.read(refreshTickProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);
    final assignmentAsync =
        ref.watch(activeAssignmentForBoxProvider(widget.boxId));
    final dashboardAsync = ref.watch(dashboardBoxesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Box Detail')),
      body: assignmentAsync.when(
        data: (assignment) {
          if (assignment == null) {
            return const Center(child: Text('This box is currently vacant.'));
          }

          final totalAsync = ref.watch(assignmentTotalProvider(assignment.id));
          final entriesAsync = ref.watch(assignmentEntriesProvider(assignment.id));
          DashboardBoxSummary? summary;
          for (final row in dashboardAsync.valueOrNull ?? <DashboardBoxSummary>[]) {
            if (row.boxId == widget.boxId) {
              summary = row;
              break;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (summary != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'BOX ${summary.boxNumber}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(summary.sellerName ?? 'Vacant'),
                  ),
                  const SizedBox(height: 12),
                ],
                totalAsync.when(
                  data: (total) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currency.format(total),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => Text(error.toString()),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('item-name'),
                  controller: _itemController,
                  decoration: const InputDecoration(labelText: 'Item name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('item-price'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('claimer-name'),
                  controller: _claimerController,
                  decoration: const InputDecoration(labelText: 'Claimer name'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _submit(assignment.id),
                  child: const Text('Add Entry'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: entriesAsync.when(
                    data: (entries) => ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          title: Text(entry.itemName),
                          subtitle: Text(entry.claimerName),
                          trailing: Text(currency.format(entry.price)),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text(error.toString()),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
```

Update the `onTap` callback in `lib/features/dashboard/dashboard_screen.dart`:

```dart
onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BoxDetailScreen(boxId: summary.boxId),
    ),
  );
},
```

- [ ] **Step 5: Run the box-detail test and verify it passes**

Run:

```bash
flutter test test/features/boxes/box_detail_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 6: Commit the box detail flow**

Run:

```bash
git add lib/features/boxes lib/providers/box_detail_providers.dart lib/features/dashboard/dashboard_screen.dart lib/database/app_database.dart test/features/boxes
git commit -m "feat: add rapid entry box detail screen"
```

### Task 8: Implement The Seller History Screen

**Files:**
- Modify: `lib/database/app_database.dart`
- Create: `lib/providers/seller_providers.dart`
- Create: `lib/features/sellers/seller_history_screen.dart`
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Create: `test/features/sellers/seller_history_screen_test.dart`
- Test: `test/features/sellers/seller_history_screen_test.dart`

- [ ] **Step 1: Write the failing seller-history widget test**

Create `test/features/sellers/seller_history_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/sellers/seller_history_screen.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows active boxes and lifetime totals for a seller',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sellerId = await db.createSeller(name: 'Mae');
    final box01 = await db.createBox(boxNumber: '01');
    final box02 = await db.createBox(boxNumber: '02');

    final closedAssignment =
        await db.createRentalAssignment(sellerId: sellerId, boxId: box01);
    await db.addLogEntry(
      rentalAssignmentId: closedAssignment,
      itemName: 'Dress',
      price: 200,
      claimerName: 'Cashier',
    );
    await db.reassignBox(
      boxId: box01,
      nextSellerId: await db.createSeller(name: 'Ella'),
    );

    final activeAssignment =
        await db.createRentalAssignment(sellerId: sellerId, boxId: box02);
    await db.addLogEntry(
      rentalAssignmentId: activeAssignment,
      itemName: 'Bag',
      price: 150,
      claimerName: 'Cashier',
    );

    await tester.pumpWidget(
      wrapWithTestApp(
        SellerHistoryScreen(sellerId: sellerId),
        overrides: [databaseProvider.overrideWithValue(db)],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mae'), findsOneWidget);
    expect(find.text('BOX 02'), findsOneWidget);
    expect(find.text('₱ 350.00'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run the seller-history test and verify it fails**

Run:

```bash
flutter test test/features/sellers/seller_history_screen_test.dart
```

Expected:
- FAIL because seller history queries and UI do not exist yet

- [ ] **Step 3: Add seller-history queries and providers**

Append to `lib/database/app_database.dart`:

```dart
  Future<String?> sellerNameById(String sellerId) async {
    final seller = await (select(sellers)..where((tbl) => tbl.id.equals(sellerId)))
        .getSingleOrNull();
    return seller?.name;
  }

  Stream<List<SellerHistoryRecord>> watchSellerHistory(String sellerId) {
    return (select(rentalAssignments)
          ..where((tbl) => tbl.sellerId.equals(sellerId)))
        .watch()
        .asyncMap((assignments) async {
      final allBoxes = await select(boxes).get();
      final allEntries = await select(logEntries).get();

      final rows = assignments.map((assignment) {
        final box = allBoxes.firstWhere((row) => row.id == assignment.boxId);
        final total = allEntries
            .where((entry) => entry.rentalAssignmentId == assignment.id)
            .fold<double>(0, (sum, row) => sum + row.price);

        return SellerHistoryRecord(
          assignmentId: assignment.id,
          boxNumber: box.boxNumber,
          startedAt: assignment.startedAt,
          endedAt: assignment.endedAt,
          total: total,
          isActive: assignment.endedAt == null,
        );
      }).toList();

      rows.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return rows;
    });
  }
```

Create `lib/providers/seller_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';

final sellerNameProvider = FutureProvider.family((ref, String sellerId) {
  return ref.watch(databaseProvider).sellerNameById(sellerId);
});

final sellerHistoryProvider = StreamProvider.family((ref, String sellerId) {
  ref.watch(refreshTickProvider);
  return ref.watch(databaseProvider).watchSellerHistory(sellerId);
});
```

- [ ] **Step 4: Implement the seller-history screen and navigation**

Create `lib/features/sellers/seller_history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/seller_providers.dart';

class SellerHistoryScreen extends ConsumerWidget {
  const SellerHistoryScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerName = ref.watch(sellerNameProvider(sellerId));
    final history = ref.watch(sellerHistoryProvider(sellerId));
    final currency = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Seller History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sellerName.when(
              data: (value) => Text(
                value ?? 'Unknown Seller',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => Text(error.toString()),
            ),
            const SizedBox(height: 12),
            history.when(
              data: (rows) {
                final lifetimeTotal =
                    rows.fold<double>(0, (sum, row) => sum + row.total);
                final activeBoxes =
                    rows.where((row) => row.isActive).map((row) => 'BOX ${row.boxNumber}');

                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lifetime total: ${currency.format(lifetimeTotal)}'),
                      const SizedBox(height: 8),
                      Text('Active boxes: ${activeBoxes.join(', ')}'),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return ListTile(
                              title: Text('BOX ${row.boxNumber}'),
                              subtitle: Text(
                                row.isActive ? 'Active rental' : 'Past rental',
                              ),
                              trailing: Text(currency.format(row.total)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Text(error.toString()),
            ),
          ],
        ),
      ),
    );
  }
}
```

Update the `onSellerTap` callback in `lib/features/dashboard/dashboard_screen.dart`:

```dart
onSellerTap: () {
  if (summary.sellerId == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SellerHistoryScreen(sellerId: summary.sellerId!),
    ),
  );
},
```

- [ ] **Step 5: Run the seller-history test and verify it passes**

Run:

```bash
flutter test test/features/sellers/seller_history_screen_test.dart
```

Expected:
- PASS

- [ ] **Step 6: Commit the seller-history screen**

Run:

```bash
git add lib/features/sellers lib/providers/seller_providers.dart lib/features/dashboard/dashboard_screen.dart lib/database/app_database.dart test/features/sellers
git commit -m "feat: add seller history records"
```

### Task 9: Regenerate Code, Analyze, And Run The Full Test Suite

**Files:**
- Modify: generated `lib/database/app_database.g.dart`
- Test: full suite under `test/`

- [ ] **Step 1: Regenerate Drift output after all schema/query changes**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected:
- `lib/database/app_database.g.dart` is up to date

- [ ] **Step 2: Run static analysis**

Run:

```bash
flutter analyze
```

Expected:
- `No issues found!`

- [ ] **Step 3: Run the full widget and database test suite**

Run:

```bash
flutter test
```

Expected:
- PASS for `widget_test.dart`
- PASS for `test/database/app_database_test.dart`
- PASS for all feature widget tests

- [ ] **Step 4: Manually verify the Android phone flows**

Run:

```bash
flutter run -d android
```

Expected manual checks:
- first launch opens setup because there are no assignments yet
- finishing setup lands on the dashboard
- dashboard shows two-column modern box cards
- dashboard actions add seller, add box, and reassign a box
- box detail adds entries and updates the live total immediately
- seller history shows active boxes and lifetime totals
- app still shows the same data after a stop/start cycle

- [ ] **Step 5: Commit the verified MVP**

Run:

```bash
git add .
git commit -m "feat: ship offline rent-a-box ledger mvp"
```
