import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';

class AddBoxSheet extends ConsumerStatefulWidget {
  const AddBoxSheet({super.key});

  @override
  ConsumerState<AddBoxSheet> createState() => _AddBoxSheetState();
}

class _AddBoxSheetState extends ConsumerState<AddBoxSheet> {
  final _boxController = TextEditingController();

  @override
  void dispose() {
    _boxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(databaseProvider).createBox(boxNumber: _boxController.text.trim());
    ref.read(refreshTickProvider.notifier).state++;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _boxController,
            decoration: const InputDecoration(labelText: 'Box number'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save Box')),
        ],
      ),
    );
  }
}
