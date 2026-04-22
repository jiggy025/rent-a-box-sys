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
    String? expectedSha256,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await _confirmRestore(context);
    if (!confirmed) {
      return;
    }

    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      final file = await fileLoader();
      await repository.localBackupService.restoreFromLocalFile(
        file,
        expectedSha256: expectedSha256,
      );
      ref.read(databaseResetProvider.notifier).state++;
      ref.invalidate(backupHealthProvider);
      ref.invalidate(localBackupRecordsProvider);
      ref.invalidate(cloudBackupFilesProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Backup restored.')));
      if (context.mounted) {
        navigator.pop();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $error')));
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
                            onRestore: () =>
                                _restoreFile(context, ref, () async {
                                  final repository = await ref.read(
                                    backupRepositoryProvider.future,
                                  );
                                  return repository.localFileForRecord(record);
                                }, record.sha256),
                          ),
                        )
                        .toList(growable: false),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(error.toString()),
          ),
          const SizedBox(height: 24),
          Text(
            'Google Drive Backups',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
                                final repository = await ref.read(
                                  backupRepositoryProvider.future,
                                );
                                return repository.localFileForCloudBackup(file);
                              },
                              file.sha256,
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
        trailing: TextButton(
          onPressed: onRestore,
          child: const Text('Restore'),
        ),
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
        trailing: TextButton(
          onPressed: onRestore,
          child: const Text('Restore'),
        ),
      ),
    );
  }
}
