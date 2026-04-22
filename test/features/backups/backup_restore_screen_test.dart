import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/features/backups/backup_restore_screen.dart';
import 'package:rent_a_box_sys/providers/backup_providers.dart';
import 'package:rent_a_box_sys/providers/database_provider.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows local backups and requires confirmation', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.createBackupRecord(
      fileName: 'espasyo-backup-2026-04-21-0005.db',
      localPath: 'backups/espasyo-backup-2026-04-21-0005.db',
      backupDate: '2026-04-21',
      sizeBytes: 1200,
      sha256: 'a' * 64,
      createdAt: DateTime(2026, 4, 21, 0, 5),
    );
    final records = await db.backupRecordsList();

    await tester.pumpWidget(
      wrapWithTestApp(
        const BackupRestoreScreen(),
        overrides: [
          databaseProvider.overrideWithValue(db),
          localBackupRecordsProvider.overrideWith(
            (ref) => Stream.value(records),
          ),
          cloudBackupFilesProvider.overrideWith((ref) async => const []),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Restore Backup'), findsOneWidget);
    expect(find.text('espasyo-backup-2026-04-21-0005.db'), findsOneWidget);
    await tester.tap(find.text('Restore').first);
    await tester.pumpAndSettle();
    expect(find.text('Replace current data?'), findsOneWidget);
  });
}
