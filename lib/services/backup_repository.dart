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
  BackupRepository({
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
  bool _isUploading = false;

  Future<BackupHealthSnapshot> healthSnapshot() async {
    final records = await database.backupRecordsList();
    final pending = await database.pendingBackupRecords();
    final account = await cloudBackupClient.currentAccount();
    final uploadedAt =
        records
            .map((record) => record.uploadedAt)
            .whereType<DateTime>()
            .toList()
          ..sort((left, right) => right.compareTo(left));

    return BackupHealthSnapshot(
      localBackups: records,
      pendingUploads: pending.length,
      connectedEmail: account?.email,
      lastUploadedAt: uploadedAt.isEmpty ? null : uploadedAt.first,
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
    if (_isUploading) {
      return;
    }

    final account = await cloudBackupClient.currentAccount();
    if (account == null || !await hasNetwork()) {
      return;
    }

    _isUploading = true;
    try {
      final pendingRecords = await database.pendingBackupRecords();
      for (final record in pendingRecords) {
        await database.markBackupUploading(record.id);
        try {
          final localFile = File(record.localPath);
          if (!await localFile.exists()) {
            throw StateError('Local backup file is missing.');
          }

          final driveFileId = await cloudBackupClient.uploadBackup(
            localFile: localFile,
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
    } finally {
      _isUploading = false;
    }
  }

  Future<CloudBackupAccount?> connectGoogleDrive() async {
    final account = await cloudBackupClient.signIn();
    if (account != null) {
      await uploadPendingBackups();
    }
    return account;
  }

  Future<void> disconnectGoogleDrive() {
    return cloudBackupClient.signOut();
  }

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
}
