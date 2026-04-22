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
      return pendingUploads == 1
          ? '1 pending upload'
          : '$pendingUploads pending uploads';
    }
    if (latestLocalBackup == null) {
      return 'No backups yet';
    }

    final status = BackupUploadStatus.fromDatabaseValue(
      latestLocalBackup!.status,
    );
    return status.label;
  }
}
