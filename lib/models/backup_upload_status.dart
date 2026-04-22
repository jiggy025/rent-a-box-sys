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
