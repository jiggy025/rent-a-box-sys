import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/models/backup_upload_status.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('creates and lists local backup records newest first', () async {
    await db.createBackupRecord(
      fileName: 'espasyo-backup-2026-04-21-0005.db',
      localPath: 'backups/espasyo-backup-2026-04-21-0005.db',
      backupDate: '2026-04-21',
      sizeBytes: 1200,
      sha256: 'a' * 64,
      createdAt: DateTime(2026, 4, 21, 0, 5),
    );
    await db.createBackupRecord(
      fileName: 'espasyo-backup-2026-04-22-0005.db',
      localPath: 'backups/espasyo-backup-2026-04-22-0005.db',
      backupDate: '2026-04-22',
      sizeBytes: 1400,
      sha256: 'b' * 64,
      createdAt: DateTime(2026, 4, 22, 0, 5),
    );
    final maxFileName = 'f' * 180;
    final maxLocalPath = 'backups/${'p' * (500 - 'backups/'.length)}';
    await db.createBackupRecord(
      fileName: maxFileName,
      localPath: maxLocalPath,
      backupDate: '2026-04-23',
      sizeBytes: 1600,
      sha256: 'c' * 64,
      createdAt: DateTime(2026, 4, 23, 0, 5),
    );

    final rows = await db.backupRecordsList();

    expect(rows.map((row) => row.fileName), [
      maxFileName,
      'espasyo-backup-2026-04-22-0005.db',
      'espasyo-backup-2026-04-21-0005.db',
    ]);
    expect(rows.first.status, BackupUploadStatus.localReady.databaseValue);
    expect(rows.first.fileName.length, 180);
    expect(rows.first.localPath.length, 500);
  });

  test('updates upload state and pending records', () async {
    final localReadyId = await db.createBackupRecord(
      fileName: 'espasyo-backup-2026-04-21-0005.db',
      localPath: 'backups/espasyo-backup-2026-04-21-0005.db',
      backupDate: '2026-04-21',
      sizeBytes: 1200,
      sha256: 'a' * 64,
      createdAt: DateTime(2026, 4, 21, 0, 5),
    );
    final uploadingId = await db.createBackupRecord(
      fileName: 'espasyo-backup-2026-04-21-0010.db',
      localPath: 'backups/espasyo-backup-2026-04-21-0010.db',
      backupDate: '2026-04-21',
      sizeBytes: 1250,
      sha256: 'd' * 64,
      createdAt: DateTime(2026, 4, 21, 0, 10),
    );

    await db.markBackupUploading(uploadingId);
    await db.markBackupFailed(localReadyId, 'offline');
    var pending = await db.pendingBackupRecords();

    expect(pending.map((row) => row.id), [localReadyId, uploadingId]);
    expect(pending.first.status, BackupUploadStatus.failed.databaseValue);
    expect(pending.first.lastError, 'offline');
    expect(pending.last.status, BackupUploadStatus.uploading.databaseValue);

    await db.markBackupUploaded(
      localReadyId,
      driveFileId: 'drive-123',
      uploadedAt: DateTime(2026, 4, 21, 0, 6),
    );
    pending = await db.pendingBackupRecords();
    final uploaded = await db.backupRecordById(localReadyId);

    expect(pending.map((row) => row.id), [uploadingId]);
    expect(uploaded!.status, BackupUploadStatus.uploaded.databaseValue);
    expect(uploaded.driveFileId, 'drive-123');
    expect(await db.backupRecordById(uploadingId), isNotNull);
  });

  test(
    'backup record for a date returns the latest duplicate record',
    () async {
      await db.createBackupRecord(
        fileName: 'espasyo-backup-2026-04-21-0005.db',
        localPath: 'backups/espasyo-backup-2026-04-21-0005.db',
        backupDate: '2026-04-21',
        sizeBytes: 1200,
        sha256: 'a' * 64,
        createdAt: DateTime(2026, 4, 21, 0, 5),
      );
      final latestId = await db.createBackupRecord(
        fileName: 'espasyo-backup-2026-04-21-zzz.db',
        localPath: 'backups/espasyo-backup-2026-04-21-zzz.db',
        backupDate: '2026-04-21',
        sizeBytes: 1250,
        sha256: 'b' * 64,
        createdAt: DateTime(2026, 4, 21, 0, 5),
      );

      final row = await db.backupRecordForDate('2026-04-21');

      expect(row, isNotNull);
      expect(row!.id, latestId);
      expect(row.fileName, 'espasyo-backup-2026-04-21-zzz.db');
    },
  );

  test('migrates a schema 3 database and can write backup records', () async {
    final directory = await Directory.systemTemp.createTemp('backup-migration');
    addTearDown(() => directory.delete(recursive: true));

    final dbFile = File(p.join(directory.path, 'schema3.sqlite'));
    await _createSchema3Database(dbFile);

    final migratedDb = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(() => migratedDb.close());

    final sellers = await migratedDb.watchAllSellers().first;
    final total = await migratedDb.currentBoxTotal('box-1');

    expect(sellers.map((row) => row.name), contains('Seed Seller'));
    expect(total, 275);

    final id = await migratedDb.createBackupRecord(
      fileName: 'espasyo-backup-2026-04-21-0100.db',
      localPath: 'backups/espasyo-backup-2026-04-21-0100.db',
      backupDate: '2026-04-21',
      sizeBytes: 1500,
      sha256: 'e' * 64,
      createdAt: DateTime(2026, 4, 21, 1, 0),
    );

    final row = await migratedDb.backupRecordById(id);

    expect(row, isNotNull);
    expect(row!.fileName, 'espasyo-backup-2026-04-21-0100.db');
  });
}

Future<void> _createSchema3Database(File file) async {
  final bootstrapDb = sqlite3.open(file.path);
  bootstrapDb
    ..execute('''
      CREATE TABLE sellers (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        contact_info TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        inactive_at TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''')
    ..execute('''
      CREATE TABLE boxes (
        id TEXT PRIMARY KEY NOT NULL,
        box_number TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''')
    ..execute('''
      CREATE TABLE rental_assignments (
        id TEXT PRIMARY KEY NOT NULL,
        seller_id TEXT NOT NULL,
        box_id TEXT NOT NULL,
        started_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        ended_at TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''')
    ..execute('''
      CREATE TABLE log_entries (
        id TEXT PRIMARY KEY NOT NULL,
        rental_assignment_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        price REAL NOT NULL,
        claimer_name TEXT NOT NULL,
        timestamp TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''')
    ..execute('''
      CREATE TABLE seller_adjustments (
        id TEXT PRIMARY KEY NOT NULL,
        seller_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''')
    ..execute('''
      CREATE TABLE app_preferences (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''')
    ..execute('''
      INSERT INTO sellers (
        id,
        name,
        contact_info,
        is_active,
        inactive_at,
        created_at,
        updated_at
      )
      VALUES ('seller-1', 'Seed Seller', 'seed@example.com', 1, NULL, 1776700800, 1776700800)
    ''')
    ..execute('''
      INSERT INTO boxes (
        id,
        box_number,
        is_active,
        created_at,
        updated_at
      )
      VALUES ('box-1', '01', 1, 1776700800, 1776700800)
    ''')
    ..execute('''
      INSERT INTO rental_assignments (
        id,
        seller_id,
        box_id,
        started_at,
        ended_at,
        created_at
      )
      VALUES ('assignment-1', 'seller-1', 'box-1', 1776700800, NULL, 1776700800)
    ''')
    ..execute('''
      INSERT INTO log_entries (
        id,
        rental_assignment_id,
        item_name,
        price,
        claimer_name,
        timestamp
      )
      VALUES ('log-1', 'assignment-1', 'Seed Sale', 275, 'Seed Cashier', 1776700860)
    ''')
    ..execute('''
      INSERT INTO app_preferences (
        key,
        value
      )
      VALUES ('dashboard_refresher_dismissed', '1')
    ''')
    ..execute('PRAGMA user_version = 3');
  bootstrapDb.close();
}
