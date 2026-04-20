# Espasyo Onboarding And Seller UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the forced setup wizard with an `Espasyo` splash plus dashboard-first guide, and simplify seller summaries by removing the redundant `Active Boxes Total` UI.

**Architecture:** Keep the current Drift and Riverpod seller-ledger foundation, then layer a branded splash screen in front of the existing dashboard. Move onboarding into the dashboard itself through a reactive guide card and help sheet derived from live database counts, and trim the seller list/detail screens so they focus on `Available Balance`, `Lifetime Sales`, and the existing active-box list.

**Tech Stack:** Flutter, Dart, flutter_riverpod, Drift, SQLite, Material 3, intl, google_fonts

---

## File Structure

- `assets/branding/espasyo.png`
  Responsibility: branded splash and help-sheet artwork copied into the repo from `C:\Users\Jiggyy\Downloads\Espasyo.png`
- `pubspec.yaml`
  Responsibility: register the `Espasyo` asset so Flutter can bundle it
- `lib/features/root/splash_screen.dart`
  Responsibility: short branded launch screen that transitions into the dashboard
- `lib/app/app.dart`
  Responsibility: use `SplashScreen` as the app home instead of the old root gate
- `lib/features/root/root_gate.dart`
  Responsibility: delete, because dashboard routing is no longer based on an upfront setup decision
- `lib/features/setup/setup_screen.dart`
  Responsibility: delete, because setup moves into the dashboard guide
- `lib/models/dashboard_guide_state.dart`
  Responsibility: hold the reactive onboarding counts and derived flags used by the dashboard guide
- `lib/database/app_database.dart`
  Responsibility: expose a single reactive snapshot for seller/box/assignment/log/adjustment counts
- `lib/providers/dashboard_providers.dart`
  Responsibility: surface the dashboard guide state to widgets
- `lib/features/dashboard/widgets/dashboard_guide_card.dart`
  Responsibility: render the large incomplete-setup guide card and the compact help card
- `lib/features/dashboard/widgets/dashboard_help_sheet.dart`
  Responsibility: render the reopenable full guide with `Espasyo` branding
- `lib/features/dashboard/dashboard_screen.dart`
  Responsibility: show the help icon, inline guide card, and help sheet entry points
- `lib/features/sellers/seller_detail_screen.dart`
  Responsibility: remove the `Active Boxes Total` summary card and keep only the approved seller summaries
- `lib/features/sellers/sellers_screen.dart`
  Responsibility: remove the `Active Boxes Total` mini-card while keeping active box count, available balance, and lifetime sales
- `test/features/root/app_launch_test.dart`
  Responsibility: verify the splash shows first and hands off to the dashboard
- `test/features/root/root_gate_test.dart`
  Responsibility: delete, because the old startup gate no longer exists
- `test/features/setup/setup_screen_test.dart`
  Responsibility: delete, because the old setup wizard no longer exists
- `test/features/dashboard/dashboard_onboarding_test.dart`
  Responsibility: verify the large guide, compact help card, and help sheet behavior
- `test/features/sellers/seller_detail_screen_test.dart`
  Responsibility: verify seller detail no longer shows `Active Boxes Total`
- `test/features/sellers/sellers_screen_test.dart`
  Responsibility: verify seller cards no longer show `Active Boxes Total`

### Task 1: Replace The Setup Gate With An Espasyo Splash Screen

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\assets\branding\espasyo.png`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\root\splash_screen.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\root\app_launch_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\pubspec.yaml`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\app\app.dart`
- Delete: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\root\root_gate.dart`
- Delete: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\setup\setup_screen.dart`
- Delete: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\root\root_gate_test.dart`
- Delete: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\setup\setup_screen_test.dart`
- Test: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\root\app_launch_test.dart`

- [ ] **Step 1: Write the failing launch-flow test**

Create `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\root\app_launch_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/app/app.dart';

void main() {
  testWidgets('shows Espasyo splash before dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RentABoxApp()));

    expect(find.byKey(const Key('espasyo-splash-image')), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1900));

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the launch test to verify it fails**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\root\app_launch_test.dart --reporter expanded
```

Expected:
- FAIL because `SplashScreen` does not exist
- FAIL because `RentABoxApp` still boots the old startup flow

- [ ] **Step 3: Add the bundled splash asset**

Copy the approved artwork:

```powershell
New-Item -ItemType Directory -Force 'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\assets\branding'
Copy-Item 'C:\Users\Jiggyy\Downloads\Espasyo.png' 'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\assets\branding\espasyo.png'
```

Update the `flutter` section of `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\pubspec.yaml` to include:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/branding/espasyo.png
```

- [ ] **Step 4: Implement the splash screen and app handoff**

Create `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\root\splash_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F1E8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Image(
              key: Key('espasyo-splash-image'),
              image: AssetImage('assets/branding/espasyo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
```

Update `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\app\app.dart` so the app boots into the splash:

```dart
import 'package:flutter/material.dart';

import '../features/root/splash_screen.dart';
import 'app_theme.dart';

class RentABoxApp extends StatelessWidget {
  const RentABoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent-a-Box Ledger',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
```

Delete the obsolete setup-route files:

```powershell
Remove-Item 'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\root\root_gate.dart'
Remove-Item 'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\setup\setup_screen.dart'
Remove-Item 'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\root\root_gate_test.dart'
Remove-Item 'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\setup\setup_screen_test.dart'
```

- [ ] **Step 5: Run the launch test to verify it passes**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\root\app_launch_test.dart --reporter expanded
```

Expected:
- PASS with the splash image showing first
- PASS with the dashboard appearing after the timed pump

- [ ] **Step 6: Commit the splash transition**

Run:

```powershell
git add pubspec.yaml assets/branding/espasyo.png lib/app/app.dart lib/features/root/splash_screen.dart test/features/root/app_launch_test.dart
git add -u lib/features/root/root_gate.dart lib/features/setup/setup_screen.dart test/features/root/root_gate_test.dart test/features/setup/setup_screen_test.dart
git commit -m "feat: add Espasyo splash startup flow"
```

### Task 2: Move Onboarding Into The Dashboard Guide And Help Sheet

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\models\dashboard_guide_state.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\dashboard\widgets\dashboard_guide_card.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\dashboard\widgets\dashboard_help_sheet.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\dashboard\dashboard_onboarding_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\database\app_database.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\providers\dashboard_providers.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\dashboard\dashboard_screen.dart`
- Test: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\dashboard\dashboard_onboarding_test.dart`

- [ ] **Step 1: Write the failing dashboard-guide tests**

Create `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\dashboard\dashboard_onboarding_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/dashboard/dashboard_screen.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';
import 'package:rent_a_box_sys/models/dashboard_guide_state.dart';
import 'package:rent_a_box_sys/providers/dashboard_providers.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows the full setup guide when the app is incomplete', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
          dashboardBoxesProvider.overrideWith((ref) => Stream.value(const <DashboardBoxSummary>[])),
          dashboardGuideStateProvider.overrideWith(
            (ref) => Stream.value(
              const DashboardGuideState(
                sellerCount: 0,
                boxCount: 0,
                activeAssignmentCount: 0,
                logEntryCount: 0,
                sellerAdjustmentCount: 0,
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('How to use Espasyo'), findsOneWidget);
    expect(find.text('Add your first seller'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
  });

  testWidgets('shows the compact help card once core setup is complete', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
          dashboardBoxesProvider.overrideWith((ref) => Stream.value(const <DashboardBoxSummary>[])),
          dashboardGuideStateProvider.overrideWith(
            (ref) => Stream.value(
              const DashboardGuideState(
                sellerCount: 1,
                boxCount: 1,
                activeAssignmentCount: 1,
                logEntryCount: 0,
                sellerAdjustmentCount: 0,
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Need a refresher? Open the step-by-step guide anytime.'), findsOneWidget);
    expect(find.text('Open Guide'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the guide tests to verify they fail**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\dashboard\dashboard_onboarding_test.dart --reporter expanded
```

Expected:
- FAIL because `DashboardGuideState` and `dashboardGuideStateProvider` do not exist
- FAIL because the dashboard does not render the guide/help UI yet

- [ ] **Step 3: Add the reactive guide-state model and database snapshot**

Create `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\models\dashboard_guide_state.dart`:

```dart
class DashboardGuideState {
  const DashboardGuideState({
    required this.sellerCount,
    required this.boxCount,
    required this.activeAssignmentCount,
    required this.logEntryCount,
    required this.sellerAdjustmentCount,
  });

  final int sellerCount;
  final int boxCount;
  final int activeAssignmentCount;
  final int logEntryCount;
  final int sellerAdjustmentCount;

  bool get hasSeller => sellerCount > 0;
  bool get hasBox => boxCount > 0;
  bool get hasActiveAssignment => activeAssignmentCount > 0;
  bool get hasLoggedSale => logEntryCount > 0;
  bool get hasSellerPayoutActivity => sellerAdjustmentCount > 0;
  bool get showFullGuide => !(hasSeller && hasBox && hasActiveAssignment);
}
```

Append to `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\database\app_database.dart`:

```dart
  Stream<DashboardGuideState> watchDashboardGuideState() {
    return customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM sellers) AS seller_count,
        (SELECT COUNT(*) FROM boxes WHERE is_active = 1) AS box_count,
        (SELECT COUNT(*) FROM rental_assignments WHERE ended_at IS NULL) AS active_assignment_count,
        (SELECT COUNT(*) FROM log_entries) AS log_entry_count,
        (SELECT COUNT(*) FROM seller_adjustments) AS seller_adjustment_count
      ''',
      readsFrom: {sellers, boxes, rentalAssignments, logEntries, sellerAdjustments},
    ).watchSingle().map(
      (row) => DashboardGuideState(
        sellerCount: row.read<int>('seller_count'),
        boxCount: row.read<int>('box_count'),
        activeAssignmentCount: row.read<int>('active_assignment_count'),
        logEntryCount: row.read<int>('log_entry_count'),
        sellerAdjustmentCount: row.read<int>('seller_adjustment_count'),
      ),
    );
  }
```

Update `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\providers\dashboard_providers.dart`:

```dart
import '../models/dashboard_guide_state.dart';
import 'database_provider.dart';

final dashboardGuideStateProvider = StreamProvider<DashboardGuideState>((ref) {
  return ref.watch(databaseProvider).watchDashboardGuideState();
});
```

- [ ] **Step 4: Implement the guide card, help sheet, and dashboard wiring**

Create `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\dashboard\widgets\dashboard_help_sheet.dart`:

```dart
import 'package:flutter/material.dart';

class DashboardHelpSheet extends StatelessWidget {
  const DashboardHelpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Center(
              child: SizedBox(
                height: 140,
                child: Image(
                  image: AssetImage('assets/branding/espasyo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('How to use Espasyo'),
            SizedBox(height: 12),
            Text('1. Add your first seller'),
            Text('Create the seller record before assigning any box.'),
            SizedBox(height: 12),
            Text('2. Add your first box'),
            Text('Set up the box number you want to manage.'),
            SizedBox(height: 12),
            Text('3. Occupy a vacant box'),
            Text('Assign a seller to a vacant box to begin tracking sales.'),
            SizedBox(height: 12),
            Text('4. Tap a box to add sales'),
            Text('Open a box, then record item name, price, and claimer.'),
            SizedBox(height: 12),
            Text('5. Manage seller payouts'),
            Text('Use Sellers for cash out, deductions, and inactive status.'),
          ],
        ),
      ),
    );
  }
}
```

Create `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\dashboard\widgets\dashboard_guide_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../models/dashboard_guide_state.dart';

class DashboardGuideCard extends StatelessWidget {
  const DashboardGuideCard({
    super.key,
    required this.state,
    required this.onOpenGuide,
  });

  final DashboardGuideState state;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    if (!state.showFullGuide) {
      return Card(
        child: ListTile(
          title: const Text('How to use Espasyo'),
          subtitle: const Text('Need a refresher? Open the step-by-step guide anytime.'),
          trailing: TextButton(
            onPressed: onOpenGuide,
            child: const Text('Open Guide'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How to use Espasyo'),
            const SizedBox(height: 4),
            const Text('Follow these steps to start tracking box rentals and sales.'),
            const SizedBox(height: 12),
            _GuideStepRow(label: 'Add your first seller', complete: state.hasSeller),
            _GuideStepRow(label: 'Add your first box', complete: state.hasBox),
            _GuideStepRow(label: 'Occupy a vacant box', complete: state.hasActiveAssignment),
            _GuideStepRow(label: 'Tap a box to add sales', complete: state.hasLoggedSale),
            _GuideStepRow(label: 'Manage seller payouts', complete: state.hasSellerPayoutActivity),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenGuide,
                child: const Text('Open full guide'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStepRow extends StatelessWidget {
  const _GuideStepRow({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        complete ? Icons.check_circle : Icons.radio_button_unchecked,
      ),
      title: Text(label),
    );
  }
}
```

Update `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\dashboard\dashboard_screen.dart` to wire the help icon and guide card:

```dart
import 'widgets/dashboard_guide_card.dart';
import 'widgets/dashboard_help_sheet.dart';
```

```dart
  void _openHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DashboardHelpSheet(),
    );
  }
```

```dart
    final guideAsync = ref.watch(dashboardGuideStateProvider);
```

```dart
        actions: [
          IconButton(
            onPressed: () => _openHelpSheet(context),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SellersScreen()),
              );
            },
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Sellers',
          ),
        ],
```

```dart
            guideAsync.when(
              data: (state) => Column(
                children: [
                  DashboardGuideCard(
                    state: state,
                    onOpenGuide: () => _openHelpSheet(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
```

- [ ] **Step 5: Run the guide tests to verify they pass**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\dashboard\dashboard_onboarding_test.dart --reporter expanded
```

Expected:
- PASS with the large guide shown on incomplete data
- PASS with the compact help card shown after seller + box + active assignment exist

- [ ] **Step 6: Commit the dashboard onboarding flow**

Run:

```powershell
git add lib/models/dashboard_guide_state.dart lib/database/app_database.dart lib/providers/dashboard_providers.dart
git add lib/features/dashboard/dashboard_screen.dart lib/features/dashboard/widgets/dashboard_guide_card.dart lib/features/dashboard/widgets/dashboard_help_sheet.dart
git add test/features/dashboard/dashboard_onboarding_test.dart
git commit -m "feat: move onboarding into dashboard guide"
```

### Task 3: Remove The Redundant Active Boxes Total UI

**Files:**
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\sellers\seller_detail_screen.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\sellers\sellers_screen.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\sellers\seller_detail_screen_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\sellers\sellers_screen_test.dart`
- Test: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\sellers\seller_detail_screen_test.dart`
- Test: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\sellers\sellers_screen_test.dart`

- [ ] **Step 1: Update the seller tests to expect the simpler summaries**

In `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\sellers\seller_detail_screen_test.dart`, add this assertion to the existing cash-out test after the initial pump:

```dart
expect(find.text('Active Boxes Total'), findsNothing);
expect(find.text('Available Balance'), findsOneWidget);
expect(find.text('Lifetime Sales'), findsOneWidget);
```

In `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\sellers\sellers_screen_test.dart`, replace the balance-card assertions with:

```dart
expect(find.text('Active Boxes Total'), findsNothing);
expect(find.text('Lifetime Sales'), findsWidgets);
expect(find.text('1 active box'), findsOneWidget);
```

- [ ] **Step 2: Run the seller tests to verify they fail**

Run:

```powershell
Get-Process dart, flutter_tester -ErrorAction SilentlyContinue | Stop-Process -Force
$targets = @(
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\build\native_assets',
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\.dart_tool\hooks_runner'
)
foreach ($target in $targets) {
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
  }
}
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\sellers\seller_detail_screen_test.dart test\features\sellers\sellers_screen_test.dart --reporter expanded
```

Expected:
- FAIL because the current UI still renders `Active Boxes Total`

- [ ] **Step 3: Remove the redundant summary card from the seller screens**

Update the `Wrap` in `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\sellers\seller_detail_screen.dart` to keep only two top cards:

```dart
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryPanel(
                    label: 'Available Balance',
                    value: currency.format(summary.availableBalance),
                    valueKey: const Key('seller-available-balance-value'),
                  ),
                  _SummaryPanel(
                    label: 'Lifetime Sales',
                    value: currency.format(summary.lifetimeSales),
                  ),
                ],
              ),
```

Update the body of `_SellerSummaryCard` in `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\sellers\sellers_screen.dart` to remove the row of two metric blocks and keep a single lifetime-sales block:

```dart
            const SizedBox(height: 12),
            _MetricBlock(
              label: 'Lifetime Sales',
              value: currency.format(summary.lifetimeSales),
            ),
```

Delete the old `Row` wrapper that displayed both `Active Boxes Total` and `Lifetime Sales`.

- [ ] **Step 4: Run the seller tests to verify they pass**

Run:

```powershell
Get-Process dart, flutter_tester -ErrorAction SilentlyContinue | Stop-Process -Force
$targets = @(
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\build\native_assets',
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\.dart_tool\hooks_runner'
)
foreach ($target in $targets) {
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
  }
}
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\sellers\seller_detail_screen_test.dart test\features\sellers\sellers_screen_test.dart --reporter expanded
```

Expected:
- PASS with no `Active Boxes Total` text on either seller screen
- PASS with `Available Balance`, `Lifetime Sales`, and the active-box count still visible

- [ ] **Step 5: Commit the seller-summary simplification**

Run:

```powershell
git add lib/features/sellers/seller_detail_screen.dart lib/features/sellers/sellers_screen.dart
git add test/features/sellers/seller_detail_screen_test.dart test/features/sellers/sellers_screen_test.dart
git commit -m "refactor: simplify seller summary cards"
```

### Task 4: Regenerate, Verify, And Rebuild The Arm64 Release APK

**Files:**
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\database\app_database.g.dart`
- Test: full suite under `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\`
- Build: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

- [ ] **Step 1: Regenerate Drift output after the database additions**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\dart.bat' run build_runner build --delete-conflicting-outputs
```

Expected:
- `lib/database/app_database.g.dart` regenerates without errors

- [ ] **Step 2: Run static analysis**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' analyze
```

Expected:
- `No issues found!`

- [ ] **Step 3: Run the full Flutter test suite with the native-assets cleanup workaround**

Run:

```powershell
Get-Process dart, flutter_tester -ErrorAction SilentlyContinue | Stop-Process -Force
$targets = @(
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\build\native_assets',
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\.dart_tool\hooks_runner'
)
foreach ($target in $targets) {
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
  }
}
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test --reporter expanded
```

Expected:
- `All tests passed!`

- [ ] **Step 4: Build the arm64 release APK**

Run:

```powershell
Get-Process dart, flutter_tester -ErrorAction SilentlyContinue | Stop-Process -Force
$targets = @(
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\build\native_assets',
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\.dart_tool\hooks_runner',
  'D:\rent-a-box-sys\.worktrees\task-1-bootstrap\.dart_tool\flutter_build'
)
foreach ($target in $targets) {
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
  }
}
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' build apk --release --target-platform android-arm64 --split-per-abi
```

Expected:
- PASS
- output file at `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`
- final size roughly in the same `18-19 MB` range

- [ ] **Step 5: Commit the verified onboarding and seller UI update**

Run:

```powershell
git add .
git commit -m "feat: add Espasyo onboarding and simplify seller summaries"
```

## Self-Review

- Splash screen requirement is covered by Task 1.
- Dashboard-first onboarding guide and reopenable help flow are covered by Task 2.
- Seller summary cleanup is covered by Task 3.
- Verification, Drift regeneration, and fresh arm64 APK output are covered by Task 4.
- No placeholder steps remain; every task includes explicit files, commands, and concrete code snippets.
