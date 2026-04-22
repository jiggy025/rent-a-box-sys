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
