import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/backups/backup_settings_screen.dart';
import 'package:rent_a_box_sys/features/dashboard/dashboard_screen.dart';
import 'package:rent_a_box_sys/models/backup_health_snapshot.dart';
import 'package:rent_a_box_sys/models/dashboard_box_summary.dart';
import 'package:rent_a_box_sys/providers/backup_providers.dart';
import 'package:rent_a_box_sys/providers/dashboard_providers.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows disconnected backup status and actions', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const BackupSettingsScreen(),
        overrides: [
          backupHealthProvider.overrideWith(
            (ref) async =>
                const BackupHealthSnapshot(localBackups: [], pendingUploads: 0),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('Google Drive not connected'), findsOneWidget);
    expect(find.text('Back Up Now'), findsOneWidget);
    expect(find.text('Connect Google Drive'), findsOneWidget);
    expect(find.text('View Backups'), findsOneWidget);
  });

  testWidgets('dashboard exposes backup settings entry', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const DashboardScreen(),
        overrides: [
          backupHealthProvider.overrideWith(
            (ref) async =>
                const BackupHealthSnapshot(localBackups: [], pendingUploads: 0),
          ),
          dashboardBoxesProvider.overrideWith(
            (ref) => Stream.value(const <DashboardBoxSummary>[]),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip('Backups'), findsOneWidget);
    await tester.tap(find.byTooltip('Backups'));
    await tester.pumpAndSettle();
    expect(find.text('Backups'), findsOneWidget);
  });
}
