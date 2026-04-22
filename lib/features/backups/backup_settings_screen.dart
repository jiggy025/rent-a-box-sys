import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/backup_providers.dart';
import 'backup_restore_screen.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  Future<void> _backUpNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      final record = await repository.backUpNow();
      ref.invalidate(backupHealthProvider);
      ref.invalidate(localBackupRecordsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Backup saved: ${record.fileName}')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $error')));
    }
  }

  Future<void> _connectDrive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      final account = await repository.connectGoogleDrive();
      ref.invalidate(backupHealthProvider);
      ref.invalidate(cloudBackupFilesProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            account == null
                ? 'Google Drive was not connected.'
                : 'Google Drive connected: ${account.email}',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Google Drive connection failed: $error')),
      );
    }
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
                      Text(
                        snapshot.connectedEmail ??
                            'Local backups are still active.',
                      ),
                      const SizedBox(height: 12),
                      Text('Status: ${snapshot.statusLabel}'),
                      if (latest != null)
                        Text(
                          'Last local backup: ${dateFormat.format(latest.createdAt)}',
                        ),
                      if (snapshot.lastUploadedAt != null)
                        Text(
                          'Last Drive upload: ${dateFormat.format(snapshot.lastUploadedAt!)}',
                        ),
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
