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
