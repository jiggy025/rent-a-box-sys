# Google Drive Backup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add safe local-first backups with optional Google Drive upload and restore, including reinstall recovery through the same Google account.

**Architecture:** Keep SQLite as the live source of truth. Add a backup metadata table, a local backup service that creates versioned SQLite snapshots first, a Google Drive app-data client that uploads/downloads those snapshots, and backup UI for connection, status, manual backup, and restore. Restore replaces the local database only after creating a pre-restore safety backup and then refreshes the database provider.

**Tech Stack:** Flutter, Dart, Drift, SQLite, Riverpod, path_provider, crypto, google_sign_in, googleapis Drive API, extension_google_sign_in_as_googleapis_auth, connectivity_plus

---

## External Setup Required

Before testing Google sign-in on a device or LDPlayer, create a Google Cloud OAuth Android client for this app.

- Android package/application id: `com.rentabox.ledger.rent_a_box_sys`
- Current APK signing: debug signing config is used for release builds in `android/app/build.gradle.kts`, so the debug keystore SHA-1 is enough for current local APK tests.
- If a real release keystore is added later, add that release SHA-1 as another Android OAuth client.
- Enable Google Drive API for the Google Cloud project.
- The app requests only this scope: `https://www.googleapis.com/auth/drive.appdata`

Command to inspect the local debug SHA-1 if needed:

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

---

## File Structure

- `pubspec.yaml`
  Responsibility: add backup/cloud dependencies.
- `android/app/src/main/AndroidManifest.xml`
  Responsibility: add internet permission for Google auth and Drive upload.
- `lib/database/app_database.dart`
  Responsibility: add `backup_records`, schema migration, backup metadata queries, DB path helpers, and consistent SQLite backup helper.
- `lib/database/app_database.g.dart`
  Responsibility: generated Drift output.
- `lib/models/backup_upload_status.dart`
  Responsibility: typed status values for local/cloud backup lifecycle.
- `lib/models/backup_health_snapshot.dart`
  Responsibility: settings-screen summary of local and Drive backup state.
- `lib/models/cloud_backup_file.dart`
  Responsibility: cloud backup list item returned by the Drive client.
- `lib/services/philippine_clock.dart`
  Responsibility: deterministic Philippine-date calculation with no DST assumptions.
- `lib/services/local_backup_service.dart`
  Responsibility: create, verify, checksum, retain, and restore local SQLite backup files.
- `lib/services/cloud_backup_client.dart`
  Responsibility: interface for Google Drive backup operations plus a disconnected implementation for tests/offline defaults.
- `lib/services/google_drive_backup_client.dart`
  Responsibility: real Google sign-in and Drive `appDataFolder` upload/list/download.
- `lib/services/backup_repository.dart`
  Responsibility: orchestrate local backup, network-aware pending upload, cloud list/download, and restore safety flow.
- `lib/providers/backup_providers.dart`
  Responsibility: expose backup repository, status, and actions through Riverpod.
- `lib/features/backups/backup_startup_runner.dart`
  Responsibility: run app-open catch-up backup/upload once without blocking the dashboard.
- `lib/features/backups/backup_settings_screen.dart`
  Responsibility: show backup status, connect Drive, manual backup, and navigation to restore.
- `lib/features/backups/backup_restore_screen.dart`
  Responsibility: show local and Drive backups and restore with confirmation.
- `lib/features/dashboard/dashboard_screen.dart`
  Responsibility: add backup/settings entry point in the app bar.
- `lib/features/root/splash_screen.dart`
  Responsibility: navigate to dashboard wrapped in startup backup runner.
- `test/database/backup_records_test.dart`
  Responsibility: database metadata and status transition tests.
- `test/services/local_backup_service_test.dart`
  Responsibility: local backup, daily guard, retention, checksum, and restore tests.
- `test/services/backup_repository_test.dart`
  Responsibility: fake Drive upload/download and restore orchestration tests.
- `test/features/backups/backup_settings_screen_test.dart`
  Responsibility: backup settings UI states and actions.
- `test/features/backups/backup_restore_screen_test.dart`
  Responsibility: restore list and confirmation UI.

---

## Task 1: Add Dependencies And Android Network Permission

**Files:**
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\pubspec.yaml`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\android\app\src\main\AndroidManifest.xml`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\pubspec.lock`

- [ ] **Step 1: Add backup dependencies**

Update `pubspec.yaml` dependencies:

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
  crypto: ^3.0.3
  connectivity_plus: ^6.0.3
  google_sign_in: ^6.2.1
  googleapis: ^13.2.0
  extension_google_sign_in_as_googleapis_auth: ^2.0.12
```

- [ ] **Step 2: Add Android internet permission**

In `android/app/src/main/AndroidManifest.xml`, add this directly under `<manifest ...>` and before `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

- [ ] **Step 3: Fetch dependencies**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:JAVA_HOME + '\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' pub get
```

Expected:
- command exits `0`
- `pubspec.lock` updates with the new packages

- [ ] **Step 4: Commit dependency setup**

Run:

```powershell
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml
git commit -m "chore: add Google Drive backup dependencies"
```

---

## Task 2: Add Backup Metadata Schema

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\models\backup_upload_status.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\database\backup_records_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\database\app_database.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\database\app_database.g.dart`

- [ ] **Step 1: Write the failing database tests**

Create `test/database/backup_records_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/models/backup_upload_status.dart';

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

    final rows = await db.backupRecordsList();

    expect(rows.map((row) => row.fileName), [
      'espasyo-backup-2026-04-22-0005.db',
      'espasyo-backup-2026-04-21-0005.db',
    ]);
    expect(rows.first.status, BackupUploadStatus.localReady.databaseValue);
  });

  test('updates upload state and pending records', () async {
    final id = await db.createBackupRecord(
      fileName: 'espasyo-backup-2026-04-21-0005.db',
      localPath: 'backups/espasyo-backup-2026-04-21-0005.db',
      backupDate: '2026-04-21',
      sizeBytes: 1200,
      sha256: 'a' * 64,
      createdAt: DateTime(2026, 4, 21, 0, 5),
    );

    await db.markBackupUploading(id);
    await db.markBackupFailed(id, 'offline');
    var pending = await db.pendingBackupRecords();

    expect(pending.single.id, id);
    expect(pending.single.status, BackupUploadStatus.failed.databaseValue);
    expect(pending.single.lastError, 'offline');

    await db.markBackupUploaded(
      id,
      driveFileId: 'drive-123',
      uploadedAt: DateTime(2026, 4, 21, 0, 6),
    );
    pending = await db.pendingBackupRecords();
    final uploaded = await db.backupRecordById(id);

    expect(pending, isEmpty);
    expect(uploaded!.status, BackupUploadStatus.uploaded.databaseValue);
    expect(uploaded.driveFileId, 'drive-123');
  });
}
```

- [ ] **Step 2: Run the database test to verify it fails**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:JAVA_HOME + '\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\database\backup_records_test.dart --reporter expanded
```

Expected:
- FAIL because `BackupUploadStatus`, `BackupRecords`, and database methods do not exist

- [ ] **Step 3: Add backup upload status model**

Create `lib/models/backup_upload_status.dart`:

```dart
enum BackupUploadStatus {
  localReady('local_ready'),
  uploading('uploading'),
  uploaded('uploaded'),
  failed('failed');

  const BackupUploadStatus(this.databaseValue);

  final String databaseValue;

  static BackupUploadStatus fromDatabaseValue(String value) {
    return BackupUploadStatus.values.firstWhere(
      (status) => status.databaseValue == value,
      orElse: () => BackupUploadStatus.failed,
    );
  }

  String get label => switch (this) {
    BackupUploadStatus.localReady => 'Pending upload',
    BackupUploadStatus.uploading => 'Uploading',
    BackupUploadStatus.uploaded => 'Uploaded',
    BackupUploadStatus.failed => 'Upload failed',
  };
}
```

- [ ] **Step 4: Add backup table and database methods**

In `lib/database/app_database.dart`, import the model:

```dart
import '../models/backup_upload_status.dart';
```

Add the table below `AppPreferences`:

```dart
class BackupRecords extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get fileName => text().withLength(min: 1, max: 180)();
  TextColumn get localPath => text().withLength(min: 1, max: 500)();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get backupDate => text().withLength(min: 10, max: 10)();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text().withLength(min: 64, max: 64)();
  TextColumn get status => text().withLength(min: 1, max: 40)();
  TextColumn get driveFileId => text().nullable()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {fileName},
  ];
}
```

Add `BackupRecords` to `@DriftDatabase(tables: [...])`, bump schema version to `4`, and add the migration:

```dart
if (from < 4) {
  await m.createTable(backupRecords);
}
```

Add these methods inside `AppDatabase`:

```dart
Future<String> createBackupRecord({
  required String fileName,
  required String localPath,
  required String backupDate,
  required int sizeBytes,
  required String sha256,
  required DateTime createdAt,
}) async {
  final row = await into(backupRecords).insertReturning(
    BackupRecordsCompanion.insert(
      fileName: fileName,
      localPath: localPath,
      backupDate: backupDate,
      sizeBytes: sizeBytes,
      sha256: sha256,
      status: BackupUploadStatus.localReady.databaseValue,
      createdAt: createdAt,
    ),
  );
  return row.id;
}

Future<List<BackupRecord>> backupRecordsList() {
  return (select(backupRecords)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
      .get();
}

Stream<List<BackupRecord>> watchBackupRecordsList() {
  return (select(backupRecords)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
      .watch();
}

Future<BackupRecord?> backupRecordById(String id) {
  return (select(backupRecords)..where((tbl) => tbl.id.equals(id)))
      .getSingleOrNull();
}

Future<BackupRecord?> backupRecordForDate(String backupDate) {
  return (select(backupRecords)
        ..where((tbl) => tbl.backupDate.equals(backupDate))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
      .getSingleOrNull();
}

Future<List<BackupRecord>> pendingBackupRecords() {
  return (select(backupRecords)
        ..where(
          (tbl) =>
              tbl.status.equals(BackupUploadStatus.localReady.databaseValue) |
              tbl.status.equals(BackupUploadStatus.failed.databaseValue),
        )
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
      .get();
}

Future<void> markBackupUploading(String id) {
  return (update(backupRecords)..where((tbl) => tbl.id.equals(id))).write(
    const BackupRecordsCompanion(
      status: Value('uploading'),
      lastError: Value(null),
    ),
  );
}

Future<void> markBackupUploaded(
  String id, {
  required String driveFileId,
  required DateTime uploadedAt,
}) {
  return (update(backupRecords)..where((tbl) => tbl.id.equals(id))).write(
    BackupRecordsCompanion(
      status: Value(BackupUploadStatus.uploaded.databaseValue),
      driveFileId: Value(driveFileId),
      uploadedAt: Value(uploadedAt),
      lastError: const Value(null),
    ),
  );
}

Future<void> markBackupFailed(String id, String error) {
  return (update(backupRecords)..where((tbl) => tbl.id.equals(id))).write(
    BackupRecordsCompanion(
      status: Value(BackupUploadStatus.failed.databaseValue),
      lastError: Value(error),
    ),
  );
}
```

- [ ] **Step 5: Regenerate Drift output**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:JAVA_HOME + '\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\dart.bat' run build_runner build --delete-conflicting-outputs
```

Expected:
- `lib/database/app_database.g.dart` is updated
- command exits `0`

- [ ] **Step 6: Run the database test to verify it passes**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\database\backup_records_test.dart --reporter expanded
```

Expected:
- PASS

- [ ] **Step 7: Commit backup metadata schema**

Run:

```powershell
git add lib/models/backup_upload_status.dart lib/database/app_database.dart lib/database/app_database.g.dart test/database/backup_records_test.dart
git commit -m "feat: add backup metadata records"
```

---

## Task 3: Implement Local Backup And Restore Files

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\services\philippine_clock.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\services\local_backup_service.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\services\local_backup_service_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\database\app_database.dart`

- [ ] **Step 1: Write failing local backup tests**

Create `test/services/local_backup_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  test('restore replaces database after creating a pre-restore backup', () async {
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

    expect(sellers.map((seller) => seller.name), ['Before']);
    expect(await Directory('${tempDir.path}/backups/pre-restore').exists(), isTrue);
  });
}
```

- [ ] **Step 2: Run the local backup tests to verify they fail**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\services\local_backup_service_test.dart --reporter expanded
```

Expected:
- FAIL because `AppDatabase.forFile`, clock classes, and `LocalBackupService` do not exist

- [ ] **Step 3: Add file database helpers**

In `lib/database/app_database.dart`, add a file constructor and DB path helpers:

```dart
AppDatabase.forFile(File file) : super(NativeDatabase(file));

static Future<File> databaseFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File(p.join(directory.path, 'rent_a_box_ledger.sqlite'));
}

Future<void> createConsistentBackupFile(File targetFile) async {
  if (await targetFile.exists()) {
    await targetFile.delete();
  }
  await targetFile.parent.create(recursive: true);
  final escapedPath = targetFile.path.replaceAll("'", "''");
  await customStatement("VACUUM INTO '$escapedPath'");
}
```

Update `_openConnection()` to call `AppDatabase.databaseFile()`:

```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await AppDatabase.databaseFile();
    return NativeDatabase(file);
  });
}
```

- [ ] **Step 4: Add Philippine clock service**

Create `lib/services/philippine_clock.dart`:

```dart
class PhilippineClock {
  const PhilippineClock();

  DateTime now() => DateTime.now();

  DateTime nowInPhilippines() => now().toUtc().add(const Duration(hours: 8));

  String dateStamp() {
    final ph = nowInPhilippines();
    return '${ph.year.toString().padLeft(4, '0')}-'
        '${ph.month.toString().padLeft(2, '0')}-'
        '${ph.day.toString().padLeft(2, '0')}';
  }

  String minuteStamp() {
    final ph = nowInPhilippines();
    return '${ph.hour.toString().padLeft(2, '0')}'
        '${ph.minute.toString().padLeft(2, '0')}';
  }
}

class FixedPhilippineClock extends PhilippineClock {
  const FixedPhilippineClock(this.fixedNow);

  final DateTime fixedNow;

  @override
  DateTime now() => fixedNow;
}
```

- [ ] **Step 5: Add local backup service**

Create `lib/services/local_backup_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import 'philippine_clock.dart';

class LocalBackupService {
  const LocalBackupService({
    required this.database,
    required this.documentsDirectory,
    this.clock = const PhilippineClock(),
    this.retentionCount = 30,
  });

  final AppDatabase database;
  final Directory documentsDirectory;
  final PhilippineClock clock;
  final int retentionCount;

  Directory get backupsDirectory =>
      Directory(p.join(documentsDirectory.path, 'backups'));

  Directory get preRestoreDirectory =>
      Directory(p.join(backupsDirectory.path, 'pre-restore'));

  Future<BackupRecord?> createDailyBackupIfNeeded() async {
    final backupDate = clock.dateStamp();
    final existing = await database.backupRecordForDate(backupDate);
    if (existing != null && await File(existing.localPath).exists()) {
      return null;
    }
    return createBackup(force: true);
  }

  Future<BackupRecord> createBackup({required bool force}) async {
    final backupDate = clock.dateStamp();
    if (!force) {
      final existing = await database.backupRecordForDate(backupDate);
      if (existing != null && await File(existing.localPath).exists()) {
        return existing;
      }
    }

    await backupsDirectory.create(recursive: true);
    final fileName = 'espasyo-backup-$backupDate-${clock.minuteStamp()}.db';
    final tempFile = File(p.join(backupsDirectory.path, '$fileName.tmp'));
    final finalFile = File(p.join(backupsDirectory.path, fileName));

    await database.createConsistentBackupFile(tempFile);
    if (!await tempFile.exists()) {
      throw StateError('Backup file was not created.');
    }
    final sizeBytes = await tempFile.length();
    if (sizeBytes <= 0) {
      await tempFile.delete();
      throw StateError('Backup file was empty.');
    }

    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await tempFile.rename(finalFile.path);
    final checksum = await sha256.bind(finalFile.openRead()).first;

    final id = await database.createBackupRecord(
      fileName: fileName,
      localPath: finalFile.path,
      backupDate: backupDate,
      sizeBytes: sizeBytes,
      sha256: checksum.toString(),
      createdAt: clock.now(),
    );

    await pruneOldLocalBackups();
    final record = await database.backupRecordById(id);
    return record!;
  }

  Future<File> createPreRestoreSafetyBackup() async {
    await preRestoreDirectory.create(recursive: true);
    final file = File(
      p.join(
        preRestoreDirectory.path,
        'espasyo-pre-restore-${clock.dateStamp()}-${clock.minuteStamp()}.db',
      ),
    );
    await database.createConsistentBackupFile(file);
    return file;
  }

  Future<void> restoreFromLocalFile(File backupFile) async {
    if (!await backupFile.exists()) {
      throw StateError('Backup file does not exist.');
    }
    await createPreRestoreSafetyBackup();
    final target = await AppDatabase.databaseFile();
    await database.close();
    await backupFile.copy(target.path);
  }

  Future<void> pruneOldLocalBackups() async {
    final records = await database.backupRecordsList();
    final localRecords = records
        .where((record) => File(record.localPath).existsSync())
        .toList(growable: false);
    if (localRecords.length <= retentionCount) {
      return;
    }
    for (final record in localRecords.skip(retentionCount)) {
      final file = File(record.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
```

- [ ] **Step 6: Run local backup tests to verify they pass**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\services\local_backup_service_test.dart --reporter expanded
```

Expected:
- PASS

- [ ] **Step 7: Commit local backup service**

Run:

```powershell
git add lib/database/app_database.dart lib/services/philippine_clock.dart lib/services/local_backup_service.dart test/services/local_backup_service_test.dart
git commit -m "feat: add local backup service"
```

---

## Task 4: Add Google Drive Backup Client

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\models\cloud_backup_file.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\services\cloud_backup_client.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\services\google_drive_backup_client.dart`

- [ ] **Step 1: Add cloud backup file model**

Create `lib/models/cloud_backup_file.dart`:

```dart
class CloudBackupFile {
  const CloudBackupFile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.sizeBytes,
    this.sha256,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int? sizeBytes;
  final String? sha256;
}
```

- [ ] **Step 2: Add Drive client interface**

Create `lib/services/cloud_backup_client.dart`:

```dart
import 'dart:io';

import '../models/cloud_backup_file.dart';

class CloudBackupAccount {
  const CloudBackupAccount({required this.email});

  final String email;
}

abstract interface class CloudBackupClient {
  Future<CloudBackupAccount?> currentAccount();
  Future<CloudBackupAccount?> signIn();
  Future<void> signOut();
  Future<String> uploadBackup({
    required File localFile,
    required String fileName,
    required String sha256,
  });
  Future<List<CloudBackupFile>> listBackups();
  Future<File> downloadBackup({
    required CloudBackupFile file,
    required Directory destinationDirectory,
  });
}

class DisconnectedCloudBackupClient implements CloudBackupClient {
  const DisconnectedCloudBackupClient();

  @override
  Future<CloudBackupAccount?> currentAccount() async => null;

  @override
  Future<CloudBackupAccount?> signIn() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<String> uploadBackup({
    required File localFile,
    required String fileName,
    required String sha256,
  }) async {
    throw StateError('Google Drive is not connected.');
  }

  @override
  Future<List<CloudBackupFile>> listBackups() async => const [];

  @override
  Future<File> downloadBackup({
    required CloudBackupFile file,
    required Directory destinationDirectory,
  }) async {
    throw StateError('Google Drive is not connected.');
  }
}
```

- [ ] **Step 3: Add real Google Drive implementation**

Create `lib/services/google_drive_backup_client.dart`:

```dart
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;

import '../models/cloud_backup_file.dart';
import 'cloud_backup_client.dart';

class GoogleDriveBackupClient implements CloudBackupClient {
  GoogleDriveBackupClient({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]);

  final GoogleSignIn _googleSignIn;

  @override
  Future<CloudBackupAccount?> currentAccount() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      return null;
    }
    return CloudBackupAccount(email: account.email);
  }

  @override
  Future<CloudBackupAccount?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }
    return CloudBackupAccount(email: account.email);
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();

  Future<drive.DriveApi> _driveApi() async {
    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw StateError('Google Drive is not connected.');
    }
    return drive.DriveApi(client);
  }

  @override
  Future<String> uploadBackup({
    required File localFile,
    required String fileName,
    required String sha256,
  }) async {
    final api = await _driveApi();
    final metadata = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder']
      ..appProperties = {'sha256': sha256};

    final media = drive.Media(localFile.openRead(), await localFile.length());
    final uploaded = await api.files.create(
      metadata,
      uploadMedia: media,
      $fields: 'id',
    );
    final id = uploaded.id;
    if (id == null || id.isEmpty) {
      throw StateError('Google Drive did not return a file id.');
    }
    return id;
  }

  @override
  Future<List<CloudBackupFile>> listBackups() async {
    final api = await _driveApi();
    final response = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'espasyo-backup-' and trashed = false",
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,createdTime,size,appProperties)',
    );
    return (response.files ?? const <drive.File>[])
        .where((file) => file.id != null && file.name != null)
        .map(
          (file) => CloudBackupFile(
            id: file.id!,
            name: file.name!,
            createdAt: file.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0),
            sizeBytes: int.tryParse(file.size ?? ''),
            sha256: file.appProperties?['sha256'],
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<File> downloadBackup({
    required CloudBackupFile file,
    required Directory destinationDirectory,
  }) async {
    final api = await _driveApi();
    await destinationDirectory.create(recursive: true);
    final response = await api.files.get(
      file.id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    final media = response as drive.Media;
    final destination = File(p.join(destinationDirectory.path, file.name));
    final sink = destination.openWrite();
    await media.stream.pipe(sink);
    return destination;
  }
}
```

- [ ] **Step 4: Run analysis for the client code**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' analyze
```

Expected:
- `No issues found!`

- [ ] **Step 5: Commit Drive client abstraction**

Run:

```powershell
git add lib/models/cloud_backup_file.dart lib/services/cloud_backup_client.dart lib/services/google_drive_backup_client.dart
git commit -m "feat: add Google Drive backup client"
```

---

## Task 5: Add Backup Repository And Providers

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\models\backup_health_snapshot.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\services\backup_repository.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\providers\backup_providers.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\services\backup_repository_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\providers\database_provider.dart`

- [ ] **Step 1: Write failing repository tests**

Create `test/services/backup_repository_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/models/backup_upload_status.dart';
import 'package:rent_a_box_sys/models/cloud_backup_file.dart';
import 'package:rent_a_box_sys/services/backup_repository.dart';
import 'package:rent_a_box_sys/services/cloud_backup_client.dart';
import 'package:rent_a_box_sys/services/local_backup_service.dart';
import 'package:rent_a_box_sys/services/philippine_clock.dart';

class FakeCloudBackupClient implements CloudBackupClient {
  CloudBackupAccount? account = const CloudBackupAccount(email: 'owner@gmail.com');
  final uploadedNames = <String>[];
  File? fileToDownload;

  @override
  Future<CloudBackupAccount?> currentAccount() async => account;

  @override
  Future<CloudBackupAccount?> signIn() async => account;

  @override
  Future<void> signOut() async => account = null;

  @override
  Future<String> uploadBackup({
    required File localFile,
    required String fileName,
    required String sha256,
  }) async {
    uploadedNames.add(fileName);
    return 'drive-$fileName';
  }

  @override
  Future<List<CloudBackupFile>> listBackups() async => [
    CloudBackupFile(
      id: 'drive-1',
      name: 'espasyo-backup-2026-04-21-0005.db',
      createdAt: DateTime(2026, 4, 21, 0, 5),
    ),
  ];

  @override
  Future<File> downloadBackup({
    required CloudBackupFile file,
    required Directory destinationDirectory,
  }) async {
    await destinationDirectory.create(recursive: true);
    final copy = File('${destinationDirectory.path}/${file.name}');
    await fileToDownload!.copy(copy.path);
    return copy;
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late FakeCloudBackupClient cloud;
  late BackupRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('espasyo_repo_test_');
    db = AppDatabase.forFile(File('${tempDir.path}/rent_a_box_ledger.sqlite'));
    cloud = FakeCloudBackupClient();
    repository = BackupRepository(
      database: db,
      localBackupService: LocalBackupService(
        database: db,
        documentsDirectory: tempDir,
        clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
      ),
      cloudBackupClient: cloud,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('manual backup creates local file and uploads when connected', () async {
    await db.createSeller(name: 'Jiggy');

    final record = await repository.backUpNow();

    expect(record.fileName, 'espasyo-backup-2026-04-21-0005.db');
    expect(cloud.uploadedNames, [record.fileName]);
    final updated = await db.backupRecordById(record.id);
    expect(updated!.driveFileId, 'drive-${record.fileName}');
  });

  test('startup maintenance leaves local backup pending when disconnected', () async {
    cloud.account = null;

    await repository.runStartupMaintenance();

    final pending = await db.pendingBackupRecords();
    expect(pending, hasLength(1));
    expect(cloud.uploadedNames, isEmpty);
  });

  test('startup maintenance leaves local backup pending when offline', () async {
    repository = BackupRepository(
      database: db,
      localBackupService: LocalBackupService(
        database: db,
        documentsDirectory: tempDir,
        clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
      ),
      cloudBackupClient: cloud,
      documentsDirectory: tempDir,
      clock: FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5)),
      hasNetwork: () async => false,
    );

    await repository.runStartupMaintenance();

    final pending = await db.pendingBackupRecords();
    expect(pending, hasLength(1));
    expect(pending.single.status, BackupUploadStatus.localReady.databaseValue);
    expect(cloud.uploadedNames, isEmpty);
  });
}
```

- [ ] **Step 2: Run repository tests to verify they fail**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\services\backup_repository_test.dart --reporter expanded
```

Expected:
- FAIL because repository and health snapshot do not exist

- [ ] **Step 3: Add backup health snapshot**

Create `lib/models/backup_health_snapshot.dart`:

```dart
import '../database/app_database.dart';
import 'backup_upload_status.dart';

class BackupHealthSnapshot {
  const BackupHealthSnapshot({
    required this.localBackups,
    required this.pendingUploads,
    this.connectedEmail,
    this.lastUploadedAt,
  });

  final List<BackupRecord> localBackups;
  final int pendingUploads;
  final String? connectedEmail;
  final DateTime? lastUploadedAt;

  bool get isDriveConnected => connectedEmail != null;

  BackupRecord? get latestLocalBackup =>
      localBackups.isEmpty ? null : localBackups.first;

  String get statusLabel {
    if (pendingUploads > 0) {
      return '$pendingUploads pending upload';
    }
    if (latestLocalBackup == null) {
      return 'No backups yet';
    }
    final status = BackupUploadStatus.fromDatabaseValue(latestLocalBackup!.status);
    return status.label;
  }
}
```

- [ ] **Step 4: Add repository**

Create `lib/services/backup_repository.dart`:

```dart
import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../models/backup_health_snapshot.dart';
import '../models/cloud_backup_file.dart';
import 'cloud_backup_client.dart';
import 'local_backup_service.dart';
import 'philippine_clock.dart';

Future<bool> _alwaysOnline() async => true;

class BackupRepository {
  const BackupRepository({
    required this.database,
    required this.localBackupService,
    required this.cloudBackupClient,
    required this.documentsDirectory,
    this.clock = const PhilippineClock(),
    this.hasNetwork = _alwaysOnline,
  });

  final AppDatabase database;
  final LocalBackupService localBackupService;
  final CloudBackupClient cloudBackupClient;
  final Directory documentsDirectory;
  final PhilippineClock clock;
  final Future<bool> Function() hasNetwork;

  Future<BackupHealthSnapshot> healthSnapshot() async {
    final rows = await database.backupRecordsList();
    final pending = await database.pendingBackupRecords();
    final account = await cloudBackupClient.currentAccount();
    final uploaded = rows
        .where((row) => row.uploadedAt != null)
        .map((row) => row.uploadedAt!)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return BackupHealthSnapshot(
      localBackups: rows,
      pendingUploads: pending.length,
      connectedEmail: account?.email,
      lastUploadedAt: uploaded.isEmpty ? null : uploaded.first,
    );
  }

  Stream<List<BackupRecord>> watchLocalBackups() {
    return database.watchBackupRecordsList();
  }

  Future<BackupRecord> backUpNow() async {
    final record = await localBackupService.createBackup(force: true);
    await uploadPendingBackups();
    return (await database.backupRecordById(record.id)) ?? record;
  }

  Future<void> runStartupMaintenance() async {
    await localBackupService.createDailyBackupIfNeeded();
    await uploadPendingBackups();
  }

  Future<void> uploadPendingBackups() async {
    final account = await cloudBackupClient.currentAccount();
    if (account == null) {
      return;
    }
    if (!await hasNetwork()) {
      return;
    }
    final pending = await database.pendingBackupRecords();
    for (final record in pending) {
      await database.markBackupUploading(record.id);
      try {
        final driveFileId = await cloudBackupClient.uploadBackup(
          localFile: File(record.localPath),
          fileName: record.fileName,
          sha256: record.sha256,
        );
        await database.markBackupUploaded(
          record.id,
          driveFileId: driveFileId,
          uploadedAt: clock.now(),
        );
      } catch (error) {
        await database.markBackupFailed(record.id, error.toString());
      }
    }
  }

  Future<CloudBackupAccount?> connectGoogleDrive() async {
    final account = await cloudBackupClient.signIn();
    if (account != null) {
      await uploadPendingBackups();
    }
    return account;
  }

  Future<void> disconnectGoogleDrive() => cloudBackupClient.signOut();

  Future<List<CloudBackupFile>> cloudBackups() {
    return cloudBackupClient.listBackups();
  }

  Future<File> downloadCloudBackup(CloudBackupFile file) {
    return cloudBackupClient.downloadBackup(
      file: file,
      destinationDirectory: Directory(
        p.join(documentsDirectory.path, 'backups', 'cloud-downloads'),
      ),
    );
  }
}
```

- [ ] **Step 5: Add database reset provider**

Modify `lib/providers/database_provider.dart`:

```dart
final databaseResetProvider = StateProvider<int>((ref) => 0);

final databaseProvider = Provider<AppDatabase>((ref) {
  ref.watch(databaseResetProvider);
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

- [ ] **Step 6: Add backup providers**

Create `lib/providers/backup_providers.dart`:

```dart
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/backup_health_snapshot.dart';
import '../services/backup_repository.dart';
import '../services/cloud_backup_client.dart';
import '../services/google_drive_backup_client.dart';
import '../services/local_backup_service.dart';
import 'database_provider.dart';

final documentsDirectoryProvider = FutureProvider<Directory>((ref) {
  return getApplicationDocumentsDirectory();
});

final cloudBackupClientProvider = Provider<CloudBackupClient>((ref) {
  return GoogleDriveBackupClient();
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final backupRepositoryProvider = FutureProvider<BackupRepository>((ref) async {
  final db = ref.watch(databaseProvider);
  final directory = await ref.watch(documentsDirectoryProvider.future);
  return BackupRepository(
    database: db,
    localBackupService: LocalBackupService(
      database: db,
      documentsDirectory: directory,
    ),
    cloudBackupClient: ref.watch(cloudBackupClientProvider),
    documentsDirectory: directory,
    hasNetwork: () async {
      final results = await ref.read(connectivityProvider).checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    },
  );
});

final backupHealthProvider = FutureProvider<BackupHealthSnapshot>((ref) async {
  final repository = await ref.watch(backupRepositoryProvider.future);
  return repository.healthSnapshot();
});

final localBackupRecordsProvider = StreamProvider((ref) async* {
  final repository = await ref.watch(backupRepositoryProvider.future);
  yield* repository.watchLocalBackups();
});
```

- [ ] **Step 7: Run repository tests to verify they pass**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\services\backup_repository_test.dart --reporter expanded
```

Expected:
- PASS

- [ ] **Step 8: Commit repository and providers**

Run:

```powershell
git add lib/models/backup_health_snapshot.dart lib/services/backup_repository.dart lib/providers/backup_providers.dart lib/providers/database_provider.dart test/services/backup_repository_test.dart
git commit -m "feat: add backup repository"
```

---

## Task 6: Add Startup Catch-Up And Backup Settings UI

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\backups\backup_startup_runner.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\backups\backup_settings_screen.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\backups\backup_settings_screen_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\root\splash_screen.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\dashboard\dashboard_screen.dart`

- [ ] **Step 1: Write failing settings screen test**

Create `test/features/backups/backup_settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/features/backups/backup_settings_screen.dart';
import 'package:rent_a_box_sys/models/backup_health_snapshot.dart';
import 'package:rent_a_box_sys/providers/backup_providers.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows disconnected backup status and actions', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const BackupSettingsScreen(),
        overrides: [
          backupHealthProvider.overrideWith(
            (ref) async => const BackupHealthSnapshot(
              localBackups: [],
              pendingUploads: 0,
            ),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('Google Drive not connected'), findsOneWidget);
    expect(find.text('Back Up Now'), findsOneWidget);
    expect(find.text('Connect Google Drive'), findsOneWidget);
  });

  testWidgets('dashboard exposes backup settings entry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [
              IconButton(
                onPressed: null,
                tooltip: 'Backups',
                icon: Icon(Icons.cloud_upload_outlined),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byTooltip('Backups'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run settings UI test to verify it fails**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\backups\backup_settings_screen_test.dart --reporter expanded
```

Expected:
- FAIL because `BackupSettingsScreen` does not exist

- [ ] **Step 3: Add startup runner**

Create `lib/features/backups/backup_startup_runner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/backup_providers.dart';

class BackupStartupRunner extends ConsumerStatefulWidget {
  const BackupStartupRunner({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BackupStartupRunner> createState() =>
      _BackupStartupRunnerState();
}

class _BackupStartupRunnerState extends ConsumerState<BackupStartupRunner> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final repository = await ref.read(backupRepositoryProvider.future);
      await repository.runStartupMaintenance();
      if (mounted) {
        ref.invalidate(backupHealthProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Modify `lib/features/root/splash_screen.dart` so `_goToDashboard` navigates to:

```dart
MaterialPageRoute(
  builder: (_) => const BackupStartupRunner(child: DashboardScreen()),
)
```

Add import:

```dart
import '../backups/backup_startup_runner.dart';
```

- [ ] **Step 4: Add backup settings screen**

Create `lib/features/backups/backup_settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/backup_providers.dart';
import 'backup_restore_screen.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  Future<void> _backUpNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = await ref.read(backupRepositoryProvider.future);
    final record = await repository.backUpNow();
    ref.invalidate(backupHealthProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('Backup saved: ${record.fileName}')),
    );
  }

  Future<void> _connectDrive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = await ref.read(backupRepositoryProvider.future);
    final account = await repository.connectGoogleDrive();
    ref.invalidate(backupHealthProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          account == null
              ? 'Google Drive was not connected.'
              : 'Google Drive connected: ${account.email}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(backupHealthProvider);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Backups')),
      body: health.when(
        data: (snapshot) {
          final latest = snapshot.latestLocalBackup;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.isDriveConnected
                            ? 'Google Drive connected'
                            : 'Google Drive not connected',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(snapshot.connectedEmail ?? 'Local backups are still active.'),
                      const SizedBox(height: 12),
                      Text('Status: ${snapshot.statusLabel}'),
                      if (latest != null)
                        Text('Last local backup: ${dateFormat.format(latest.createdAt)}'),
                      if (snapshot.lastUploadedAt != null)
                        Text('Last Drive upload: ${dateFormat.format(snapshot.lastUploadedAt!)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _backUpNow(context, ref),
                icon: const Icon(Icons.backup_outlined),
                label: const Text('Back Up Now'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _connectDrive(context, ref),
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('Connect Google Drive'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BackupRestoreScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.restore_outlined),
                label: const Text('View Backups'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
```

- [ ] **Step 5: Add dashboard entry point**

In `lib/features/dashboard/dashboard_screen.dart`, import backup settings:

```dart
import '../backups/backup_settings_screen.dart';
```

Add this `IconButton` before Help in the app bar actions:

```dart
IconButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
    );
  },
  icon: const Icon(Icons.cloud_upload_outlined),
  tooltip: 'Backups',
),
```

- [ ] **Step 6: Run settings UI test to verify it passes**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\backups\backup_settings_screen_test.dart --reporter expanded
```

Expected:
- PASS

- [ ] **Step 7: Commit backup settings UI**

Run:

```powershell
git add lib/features/backups/backup_startup_runner.dart lib/features/backups/backup_settings_screen.dart lib/features/root/splash_screen.dart lib/features/dashboard/dashboard_screen.dart test/features/backups/backup_settings_screen_test.dart
git commit -m "feat: add backup settings screen"
```

---

## Task 7: Add Restore From Local And Google Drive Backups

**Files:**
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\features\backups\backup_restore_screen.dart`
- Create: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\test\features\backups\backup_restore_screen_test.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\services\backup_repository.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\services\local_backup_service.dart`
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\providers\database_provider.dart`

- [ ] **Step 1: Write failing restore screen test**

Create `test/features/backups/backup_restore_screen_test.dart`:

```dart
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

    await tester.pumpWidget(
      wrapWithTestApp(
        const BackupRestoreScreen(),
        overrides: [
          databaseProvider.overrideWithValue(db),
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
```

- [ ] **Step 2: Run restore UI test to verify it fails**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\backups\backup_restore_screen_test.dart --reporter expanded
```

Expected:
- FAIL because `BackupRestoreScreen` and `cloudBackupFilesProvider` do not exist

- [ ] **Step 3: Add cloud backup provider and restore methods**

Add to `lib/providers/backup_providers.dart`:

```dart
final cloudBackupFilesProvider = FutureProvider((ref) async {
  final repository = await ref.watch(backupRepositoryProvider.future);
  return repository.cloudBackups();
});
```

Add to `BackupRepository`:

```dart
Future<File> localFileForRecord(BackupRecord record) async {
  final file = File(record.localPath);
  if (!await file.exists()) {
    throw StateError('Local backup file is missing.');
  }
  return file;
}

Future<File> localFileForCloudBackup(CloudBackupFile file) {
  return downloadCloudBackup(file);
}
```

- [ ] **Step 4: Add restore screen**

Create `lib/features/backups/backup_restore_screen.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../database/app_database.dart';
import '../../models/cloud_backup_file.dart';
import '../../providers/backup_providers.dart';
import '../../providers/database_provider.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  Future<bool> _confirmRestore(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace current data?'),
            content: const Text(
              'Espasyo will create a safety backup first, then replace the current database with the selected backup.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restore'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _restoreFile(
    BuildContext context,
    WidgetRef ref,
    Future<File> Function() fileLoader,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirmRestore(context);
    if (!confirmed) {
      return;
    }

    final repository = await ref.read(backupRepositoryProvider.future);
    final file = await fileLoader();
    await repository.localBackupService.restoreFromLocalFile(file);
    ref.read(databaseResetProvider.notifier).state++;
    ref.invalidate(backupHealthProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Backup restored.')),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localBackups = ref.watch(localBackupRecordsProvider);
    final cloudBackups = ref.watch(cloudBackupFilesProvider);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Restore Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Local Backups', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          localBackups.when(
            data: (rows) => rows.isEmpty
                ? const Text('No local backups yet.')
                : Column(
                    children: rows
                        .map(
                          (record) => _LocalBackupTile(
                            record: record,
                            subtitle: dateFormat.format(record.createdAt),
                            onRestore: () => _restoreFile(
                              context,
                              ref,
                              () async {
                                final repository =
                                    await ref.read(backupRepositoryProvider.future);
                                return repository.localFileForRecord(record);
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(error.toString()),
          ),
          const SizedBox(height: 24),
          Text('Google Drive Backups', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          cloudBackups.when(
            data: (rows) => rows.isEmpty
                ? const Text('No Google Drive backups found.')
                : Column(
                    children: rows
                        .map(
                          (file) => _CloudBackupTile(
                            file: file,
                            subtitle: dateFormat.format(file.createdAt),
                            onRestore: () => _restoreFile(
                              context,
                              ref,
                              () async {
                                final repository =
                                    await ref.read(backupRepositoryProvider.future);
                                return repository.localFileForCloudBackup(file);
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(error.toString()),
          ),
        ],
      ),
    );
  }
}

class _LocalBackupTile extends StatelessWidget {
  const _LocalBackupTile({
    required this.record,
    required this.subtitle,
    required this.onRestore,
  });

  final BackupRecord record;
  final String subtitle;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(record.fileName),
        subtitle: Text(subtitle),
        trailing: TextButton(onPressed: onRestore, child: const Text('Restore')),
      ),
    );
  }
}

class _CloudBackupTile extends StatelessWidget {
  const _CloudBackupTile({
    required this.file,
    required this.subtitle,
    required this.onRestore,
  });

  final CloudBackupFile file;
  final String subtitle;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(file.name),
        subtitle: Text(subtitle),
        trailing: TextButton(onPressed: onRestore, child: const Text('Restore')),
      ),
    );
  }
}
```

- [ ] **Step 5: Run restore UI test to verify it passes**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test test\features\backups\backup_restore_screen_test.dart --reporter expanded
```

Expected:
- PASS

- [ ] **Step 6: Commit restore flow**

Run:

```powershell
git add lib/features/backups/backup_restore_screen.dart lib/providers/backup_providers.dart lib/services/backup_repository.dart test/features/backups/backup_restore_screen_test.dart
git commit -m "feat: add backup restore flow"
```

---

## Task 8: Regenerate, Verify, And Rebuild APK

**Files:**
- Modify: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\lib\database\app_database.g.dart`
- Build: `D:\rent-a-box-sys\.worktrees\task-1-bootstrap\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

- [ ] **Step 1: Regenerate Drift output**

Run:

```powershell
$env:JAVA_HOME='D:\rent-a-box-sys\.superpowers\jdk17\jdk-17.0.18+8'
$env:ANDROID_SDK_ROOT='D:\rent-a-box-sys\.superpowers\android-sdk'
$env:PATH='D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin;D:\rent-a-box-sys\.superpowers\android-sdk\platform-tools;D:\rent-a-box-sys\.superpowers\android-sdk\cmdline-tools\latest\bin;' + $env:JAVA_HOME + '\bin;' + $env:PATH
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\dart.bat' run build_runner build --delete-conflicting-outputs
```

Expected:
- command exits `0`

- [ ] **Step 2: Run static analysis**

Run:

```powershell
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' analyze
```

Expected:
- `No issues found!`

- [ ] **Step 3: Run full test suite**

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
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' test --reporter expanded
```

Expected:
- `All tests passed!`

- [ ] **Step 4: Build arm64 release APK**

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
& 'D:\rent-a-box-sys\.superpowers\flutter-sdk\sdk\flutter\bin\flutter.bat' build apk --release --target-platform android-arm64 --split-per-abi
```

Expected:
- `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` exists
- APK installs in LDPlayer

- [ ] **Step 5: Manual verification checklist**

On LDPlayer:
- install the APK
- open Espasyo with no internet and tap `Backups`
- tap `Back Up Now` and confirm local backup success
- connect internet
- tap `Connect Google Drive`
- confirm Drive status shows connected account
- tap `Back Up Now` and confirm pending upload clears
- uninstall the app
- reinstall the app
- connect the same Google account
- open `View Backups`
- restore a Google Drive backup
- confirm sellers, boxes, assignments, and entries reappear

- [ ] **Step 6: Commit verified backup feature**

Run:

```powershell
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml lib/database/app_database.dart lib/database/app_database.g.dart lib/models/backup_upload_status.dart lib/models/backup_health_snapshot.dart lib/models/cloud_backup_file.dart lib/services/philippine_clock.dart lib/services/local_backup_service.dart lib/services/cloud_backup_client.dart lib/services/google_drive_backup_client.dart lib/services/backup_repository.dart lib/providers/database_provider.dart lib/providers/backup_providers.dart lib/features/backups/backup_startup_runner.dart lib/features/backups/backup_settings_screen.dart lib/features/backups/backup_restore_screen.dart lib/features/dashboard/dashboard_screen.dart lib/features/root/splash_screen.dart test/database/backup_records_test.dart test/services/local_backup_service_test.dart test/services/backup_repository_test.dart test/features/backups/backup_settings_screen_test.dart test/features/backups/backup_restore_screen_test.dart
git commit -m "feat: add Google Drive backup and restore"
```

## Self-Review

- Spec coverage: local daily backup, Drive upload, versioned files, limited Drive scope, restore from local and Drive, app-open catch-up, and uninstall recovery are covered.
- Deferred items: Android background worker, encryption, multi-device sync, and conflict merging remain out of scope as specified.
- Placeholder scan: no `TBD`, `TODO`, `fill in`, or unspecified implementation steps remain.
- Type consistency: `BackupUploadStatus.localReady` maps to `local_ready`, `BackupRecords` generates `BackupRecord`, and providers use the same repository/service names across tasks.
