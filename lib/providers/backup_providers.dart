import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../models/backup_health_snapshot.dart';
import '../models/cloud_backup_file.dart';
import '../services/backup_repository.dart';
import '../services/cloud_backup_client.dart';
import '../services/google_drive_backup_client.dart';
import '../services/local_backup_service.dart';
import 'database_provider.dart';

final documentsDirectoryProvider = FutureProvider<Directory>((ref) {
  return getApplicationDocumentsDirectory();
});

final cloudBackupClientProvider = Provider<CloudBackupClient>((ref) {
  final client = GoogleDriveBackupClient();
  ref.onDispose(client.close);
  return client;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final backupRepositoryProvider = FutureProvider<BackupRepository>((ref) async {
  final database = ref.watch(databaseProvider);
  final documentsDirectory = await ref.watch(documentsDirectoryProvider.future);

  return BackupRepository(
    database: database,
    localBackupService: LocalBackupService(
      database: database,
      documentsDirectory: documentsDirectory,
    ),
    cloudBackupClient: ref.watch(cloudBackupClientProvider),
    documentsDirectory: documentsDirectory,
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

final localBackupRecordsProvider = StreamProvider<List<BackupRecord>>((
  ref,
) async* {
  final repository = await ref.watch(backupRepositoryProvider.future);
  yield* repository.watchLocalBackups();
});

final cloudBackupFilesProvider = FutureProvider<List<CloudBackupFile>>((
  ref,
) async {
  final repository = await ref.watch(backupRepositoryProvider.future);
  return repository.cloudBackups();
});
