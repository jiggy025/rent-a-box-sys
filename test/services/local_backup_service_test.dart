import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/services/local_backup_service.dart';
import 'package:rent_a_box_sys/services/philippine_clock.dart';

void main() {
  late Directory tempDir;
  late File dbFile;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('espasyo_backup_test_');
    dbFile = File('${tempDir.path}/rent_a_box_ledger.sqlite');
    db = AppDatabase.forFile(dbFile);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates one local backup for the Philippine date', () async {
    await db.createSeller(name: 'Jiggy');
    final service = LocalBackupService(
      database: db,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
    );

    final first = await service.createDailyBackupIfNeeded();
    final second = await service.createDailyBackupIfNeeded();

    expect(first, isNotNull);
    expect(second, isNull);
    expect(first!.fileName, 'espasyo-backup-2026-04-21-0005.db');
    expect(await File(first.localPath).exists(), isTrue);
    expect(first.sizeBytes, greaterThan(0));
    expect(first.sha256.length, 64);
  });

  test(
    'recreates a missing local backup for the Philippine date with a suffix',
    () async {
      await db.createSeller(name: 'Jiggy');
      final service = LocalBackupService(
        database: db,
        documentsDirectory: tempDir,
        clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
      );

      final first = await service.createDailyBackupIfNeeded();
      await File(first!.localPath).delete();

      final replacement = await service.createDailyBackupIfNeeded();

      expect(replacement, isNotNull);
      expect(replacement!.fileName, 'espasyo-backup-2026-04-21-0005-2.db');
      expect(await File(replacement.localPath).exists(), isTrue);
      expect(replacement.backupDate, '2026-04-21');
    },
  );

  test('cleans stale temp files before creating a backup', () async {
    final backupsDir = Directory('${tempDir.path}/backups');
    await backupsDir.create(recursive: true);
    final staleTemp = File(
      '${backupsDir.path}/espasyo-backup-2026-04-21-0005.db.tmp',
    );
    await staleTemp.writeAsString('stale');

    final service = LocalBackupService(
      database: db,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
    );

    final backup = await service.createBackup(force: true);

    expect(await staleTemp.exists(), isFalse);
    expect(backup.fileName, 'espasyo-backup-2026-04-21-0005.db');
  });

  test('pre-restore safety backups suffix instead of overwriting', () async {
    final service = LocalBackupService(
      database: db,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
    );

    final first = await service.createPreRestoreSafetyBackup();
    final second = await service.createPreRestoreSafetyBackup();

    expect(first.path, isNot(equals(second.path)));
    expect(first.path, endsWith('espasyo-pre-restore-2026-04-21-0005.db'));
    expect(second.path, endsWith('espasyo-pre-restore-2026-04-21-0005-2.db'));
    expect(await first.exists(), isTrue);
    expect(await second.exists(), isTrue);
  });

  test('force backup creates a new timestamped backup', () async {
    final service = LocalBackupService(
      database: db,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
    );

    final backup = await service.createBackup(force: true);

    expect(backup.fileName, 'espasyo-backup-2026-04-21-0005.db');
    expect(await File(backup.localPath).exists(), isTrue);
  });

  test(
    'restore replaces database after creating a pre-restore backup',
    () async {
      await db.createSeller(name: 'Before');
      final service = LocalBackupService(
        database: db,
        documentsDirectory: tempDir,
        clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
      );
      final backup = await service.createBackup(force: true);

      await db.createSeller(name: 'After');
      await service.restoreFromLocalFile(File(backup.localPath));

      final restoredDb = AppDatabase.forFile(dbFile);
      addTearDown(restoredDb.close);
      final sellers = await restoredDb.watchAllSellers().first;
      final backups = await restoredDb.backupRecordsList();

      expect(sellers.map((seller) => seller.name), ['Before']);
      expect(
        backups.map((backup) => p.basename(backup.localPath)),
        contains('espasyo-pre-restore-2026-04-21-0005.db'),
      );
      expect(
        await Directory('${tempDir.path}/backups/pre-restore').exists(),
        isTrue,
      );
    },
  );

  test('restore cleans its temporary staging file', () async {
    await db.createSeller(name: 'Before');
    final service = LocalBackupService(
      database: db,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
    );
    final backup = await service.createBackup(force: true);

    await db.createSeller(name: 'After');
    await service.restoreFromLocalFile(File(backup.localPath));

    final restoreTemps = Directory('${tempDir.path}/backups/pre-restore')
        .listSync()
        .whereType<File>()
        .where((file) => p.basename(file.path).contains('restore-temp'))
        .toList(growable: false);
    final preparedRestoreFile = File('${dbFile.path}.restore-ready.tmp');

    expect(restoreTemps, isEmpty);
    expect(await preparedRestoreFile.exists(), isFalse);
  });

  test('restore checksum mismatch fails before side effects', () async {
    await db.createSeller(name: 'Before');
    final service = LocalBackupService(
      database: db,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
    );
    final backup = await service.createBackup(force: true);

    await expectLater(
      service.restoreFromLocalFile(
        File(backup.localPath),
        expectedSha256: '0' * 64,
      ),
      throwsStateError,
    );

    await db.createSeller(name: 'AfterFailure');
    final sellers = await db.watchAllSellers().first;

    expect(
      sellers.map((seller) => seller.name),
      containsAll(['Before', 'AfterFailure']),
    );
    expect(
      await Directory('${tempDir.path}/backups/pre-restore').exists(),
      isFalse,
    );
    expect(await dbFile.exists(), isTrue);
  });

  test(
    'orphan final backup file is removed if metadata insert fails',
    () async {
      final failingDbFile = File('${tempDir.path}/failing_rent_a_box.sqlite');
      final failingDb = _FailingBackupDatabase(failingDbFile);
      addTearDown(failingDb.close);

      final service = LocalBackupService(
        database: failingDb,
        documentsDirectory: tempDir,
        clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
      );

      final expectedFinalFile = File(
        '${tempDir.path}/backups/espasyo-backup-2026-04-21-0005.db',
      );

      await expectLater(service.createBackup(force: true), throwsStateError);

      expect(await expectedFinalFile.exists(), isFalse);
    },
  );
}

class _FailingBackupDatabase extends AppDatabase {
  _FailingBackupDatabase(super.file) : super.forFile();

  @override
  Future<String> createBackupRecord({
    required String fileName,
    required String localPath,
    required String backupDate,
    required int sizeBytes,
    required String sha256,
    required DateTime createdAt,
  }) async {
    throw StateError('metadata insert failed');
  }
}
