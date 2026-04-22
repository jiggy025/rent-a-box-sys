import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/backup_providers.dart';

class BackupStartupRunner extends ConsumerStatefulWidget {
  const BackupStartupRunner({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BackupStartupRunner> createState() =>
      _BackupStartupRunnerState();
}

class _BackupStartupRunnerState extends ConsumerState<BackupStartupRunner> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }

    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      try {
        final repository = await ref.read(backupRepositoryProvider.future);
        await repository.runStartupMaintenance();
        if (mounted) {
          ref.invalidate(backupHealthProvider);
        }
      } catch (_) {
        // Startup backups should never block the cashier from opening the app.
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
