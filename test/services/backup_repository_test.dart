import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_a_box_sys/database/app_database.dart';
import 'package:rent_a_box_sys/models/backup_upload_status.dart';
import 'package:rent_a_box_sys/models/cloud_backup_file.dart';
import 'package:rent_a_box_sys/services/backup_repository.dart';
import 'package:rent_a_box_sys/services/cloud_backup_client.dart';
import 'package:rent_a_box_sys/services/local_backup_service.dart';
import 'package:rent_a_box_sys/services/philippine_clock.dart';

class FakeCloudBackupClient implements CloudBackupClient {
  CloudBackupAccount? account = const CloudBackupAccount(
    email: 'owner@gmail.com',
  );
  final uploadedNames = <String>[];
  File? fileToDownload;

  @override
  Future<CloudBackupAccount?> currentAccount() async => account;

  @override
  Future<CloudBackupAccount?> signIn() async => account;

  @override
  Future<void> signOut() async {
    account = null;
  }

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
  Future<List<CloudBackupFile>> listBackups() async {
    return [
      CloudBackupFile(
        id: 'drive-1',
        name: 'espasyo-backup-2026-04-21-0005.db',
        createdAt: DateTime(2026, 4, 21, 0, 5),
      ),
    ];
  }

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

  BackupRepository buildRepository({Future<bool> Function()? hasNetwork}) {
    final clock = FixedPhilippineClock(DateTime.utc(2026, 4, 20, 16, 5));
    return BackupRepository(
      database: db,
      localBackupService: LocalBackupService(
        database: db,
        documentsDirectory: tempDir,
        clock: clock,
      ),
      cloudBackupClient: cloud,
      documentsDirectory: tempDir,
      clock: clock,
      hasNetwork: hasNetwork ?? () async => true,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('espasyo_repo_test_');
    db = AppDatabase.forFile(File('${tempDir.path}/rent_a_box_ledger.sqlite'));
    cloud = FakeCloudBackupClient();
    repository = buildRepository();
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('manual backup creates local file and uploads when connected', () async {
    await db.createSeller(name: 'Jiggy');

    final record = await repository.backUpNow();

    expect(record.fileName, 'espasyo-backup-2026-04-21-0005.db');
    expect(await File(record.localPath).exists(), isTrue);
    expect(cloud.uploadedNames, [record.fileName]);
    expect(record.driveFileId, 'drive-${record.fileName}');
    expect(record.status, BackupUploadStatus.uploaded.databaseValue);
  });

  test(
    'startup maintenance leaves local backup pending when disconnected',
    () async {
      cloud.account = null;

      await repository.runStartupMaintenance();

      final pending = await db.pendingBackupRecords();
      expect(pending, hasLength(1));
      expect(
        pending.single.status,
        BackupUploadStatus.localReady.databaseValue,
      );
      expect(cloud.uploadedNames, isEmpty);
    },
  );

  test(
    'startup maintenance leaves local backup pending when offline',
    () async {
      repository = buildRepository(hasNetwork: () async => false);

      await repository.runStartupMaintenance();

      final pending = await db.pendingBackupRecords();
      expect(pending, hasLength(1));
      expect(
        pending.single.status,
        BackupUploadStatus.localReady.databaseValue,
      );
      expect(cloud.uploadedNames, isEmpty);
    },
  );

  test(
    'missing local file marks backup failed and continues upload loop',
    () async {
      final missingId = await db.createBackupRecord(
        fileName: 'espasyo-backup-2026-04-20-0005.db',
        localPath: '${tempDir.path}/backups/missing.db',
        backupDate: '2026-04-20',
        sizeBytes: 1200,
        sha256: 'a' * 64,
        createdAt: DateTime(2026, 4, 20, 0, 5),
      );
      final valid = await repository.backUpNow();
      cloud.uploadedNames.clear();

      await repository.uploadPendingBackups();

      final missing = await db.backupRecordById(missingId);
      final uploaded = await db.backupRecordById(valid.id);
      expect(missing!.status, BackupUploadStatus.failed.databaseValue);
      expect(missing.lastError, contains('Local backup file is missing'));
      expect(uploaded!.status, BackupUploadStatus.uploaded.databaseValue);
      expect(cloud.uploadedNames, isEmpty);
    },
  );

  test(
    'interrupted uploading records are retried on the next upload pass',
    () async {
      final backup = await repository.backUpNow();
      await db.markBackupUploading(backup.id);
      cloud.uploadedNames.clear();

      await repository.uploadPendingBackups();

      final updated = await db.backupRecordById(backup.id);
      expect(updated!.status, BackupUploadStatus.uploaded.databaseValue);
      expect(cloud.uploadedNames, [backup.fileName]);
    },
  );

  test(
    'health snapshot summarizes pending uploads and connected account',
    () async {
      cloud.account = null;
      await repository.runStartupMaintenance();
      cloud.account = const CloudBackupAccount(email: 'owner@gmail.com');

      final snapshot = await repository.healthSnapshot();

      expect(snapshot.isDriveConnected, isTrue);
      expect(snapshot.connectedEmail, 'owner@gmail.com');
      expect(snapshot.pendingUploads, 1);
      expect(snapshot.latestLocalBackup, isNotNull);
      expect(snapshot.statusLabel, '1 pending upload');
    },
  );
}
