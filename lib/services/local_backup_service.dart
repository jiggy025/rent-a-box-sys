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
  }) : assert(retentionCount > 0, 'retentionCount must be positive.');

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
    await _cleanupStaleTempFiles();

    final baseFileName = 'espasyo-backup-$backupDate-${clock.minuteStamp()}.db';
    final finalFile = await _availableBackupFile(baseFileName);
    final tempFile = File('${finalFile.path}.tmp');
    var finalFileCreated = false;
    var metadataCreated = false;

    try {
      await database.createConsistentBackupFile(tempFile);
      if (!await tempFile.exists()) {
        throw StateError('Backup file was not created.');
      }

      final sizeBytes = await tempFile.length();
      if (sizeBytes <= 0) {
        throw StateError('Backup file was empty.');
      }

      await tempFile.rename(finalFile.path);
      finalFileCreated = true;
      final checksum = await sha256.bind(finalFile.openRead()).first;

      final id = await database.createBackupRecord(
        fileName: p.basename(finalFile.path),
        localPath: finalFile.path,
        backupDate: backupDate,
        sizeBytes: sizeBytes,
        sha256: checksum.toString(),
        createdAt: clock.now(),
      );
      metadataCreated = true;

      await pruneOldLocalBackups();
      final record = await database.backupRecordById(id);
      return record!;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      if (finalFileCreated && !metadataCreated && await finalFile.exists()) {
        await finalFile.delete();
      }
    }
  }

  Future<File> createPreRestoreSafetyBackup() async {
    await preRestoreDirectory.create(recursive: true);
    final baseFileName =
        'espasyo-pre-restore-${clock.dateStamp()}-${clock.minuteStamp()}.db';
    final file = await _availableFileInDirectory(
      preRestoreDirectory,
      baseFileName,
    );
    await database.createConsistentBackupFile(file);
    return file;
  }

  /// Closes the current database after staging the selected backup.
  ///
  /// Callers must recreate or invalidate their database provider after this
  /// succeeds so subsequent reads use the restored file.
  Future<void> restoreFromLocalFile(
    File backupFile, {
    String? expectedSha256,
  }) async {
    if (!await backupFile.exists()) {
      throw StateError('Backup file does not exist.');
    }

    if (expectedSha256 != null) {
      final actualSha256 = await _sha256ForFile(backupFile);
      if (actualSha256 != expectedSha256) {
        throw StateError('Backup file checksum mismatch.');
      }
    }

    final safetyBackup = await createPreRestoreSafetyBackup();
    final restoreTemp = await _prepareRestoreTempFile(backupFile);
    final target = await database.resolvedDatabaseFile();
    await target.parent.create(recursive: true);
    final preparedRestoreFile = File('${target.path}.restore-ready.tmp');
    try {
      await restoreTemp.copy(preparedRestoreFile.path);
      if (!await preparedRestoreFile.exists() ||
          await preparedRestoreFile.length() <= 0) {
        throw StateError('Restore staging file was not prepared.');
      }

      await database.close();
      await _deleteSqliteSidecarFiles(target);
      if (await target.exists()) {
        await target.delete();
      }
      await preparedRestoreFile.rename(target.path);
      await _deleteSqliteSidecarFiles(target);
      await _recordPreRestoreSafetyBackup(
        databaseFile: target,
        safetyBackup: safetyBackup,
      );
    } finally {
      if (await preparedRestoreFile.exists()) {
        await preparedRestoreFile.delete();
      }
      if (await restoreTemp.exists()) {
        await restoreTemp.delete();
      }
    }
  }

  Future<void> _recordPreRestoreSafetyBackup({
    required File databaseFile,
    required File safetyBackup,
  }) async {
    final restoredDatabase = AppDatabase.forFile(databaseFile);
    try {
      await restoredDatabase.customSelect('SELECT 1').getSingle();
      await restoredDatabase.createBackupRecord(
        fileName: p.basename(safetyBackup.path),
        localPath: safetyBackup.path,
        backupDate: clock.dateStamp(),
        sizeBytes: await safetyBackup.length(),
        sha256: await _sha256ForFile(safetyBackup),
        createdAt: clock.now(),
      );
    } finally {
      await restoredDatabase.close();
    }
  }

  Future<void> _deleteSqliteSidecarFiles(File databaseFile) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('${databaseFile.path}$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }
  }

  Future<void> pruneOldLocalBackups() async {
    final records = await database.backupRecordsList();
    final localRecords = <BackupRecord>[];
    for (final record in records) {
      if (await File(record.localPath).exists()) {
        localRecords.add(record);
      }
    }
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

  Future<void> _cleanupStaleTempFiles() async {
    if (!await backupsDirectory.exists()) {
      return;
    }

    await for (final entity in backupsDirectory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.path.toLowerCase().endsWith('.tmp')) {
        if (await entity.exists()) {
          await entity.delete();
        }
      }
    }
  }

  Future<File> _availableBackupFile(String baseFileName) async {
    return _availableFileInDirectory(
      backupsDirectory,
      baseFileName,
      lookupByName: _backupRecordByFileName,
    );
  }

  Future<File> _availableFileInDirectory(
    Directory directory,
    String baseFileName, {
    Future<BackupRecord?> Function(String fileName)? lookupByName,
  }) async {
    final candidate = File(p.join(directory.path, baseFileName));
    if (!await candidate.exists() &&
        (lookupByName == null || await lookupByName(baseFileName) == null)) {
      return candidate;
    }

    var suffix = 2;
    final baseName = p.basenameWithoutExtension(baseFileName);
    final extension = p.extension(baseFileName);
    while (true) {
      final fileName = '$baseName-$suffix$extension';
      final file = File(p.join(directory.path, fileName));
      if (!await file.exists() &&
          (lookupByName == null || await lookupByName(fileName) == null)) {
        return file;
      }
      suffix++;
    }
  }

  Future<File> _prepareRestoreTempFile(File backupFile) async {
    await preRestoreDirectory.create(recursive: true);
    final baseFileName =
        'espasyo-restore-temp-${clock.dateStamp()}-${clock.minuteStamp()}.db';
    final tempFile = await _availableFileInDirectory(
      preRestoreDirectory,
      baseFileName,
    );
    await backupFile.copy(tempFile.path);
    if (!await tempFile.exists()) {
      throw StateError('Restore temp file was not created.');
    }
    final sizeBytes = await tempFile.length();
    if (sizeBytes <= 0) {
      await tempFile.delete();
      throw StateError('Restore temp file was empty.');
    }
    return tempFile;
  }

  Future<BackupRecord?> _backupRecordByFileName(String fileName) {
    return (database.select(
      database.backupRecords,
    )..where((tbl) => tbl.fileName.equals(fileName))).getSingleOrNull();
  }

  Future<String> _sha256ForFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
