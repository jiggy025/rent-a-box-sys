import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';

class AddSellerSheet extends ConsumerStatefulWidget {
  const AddSellerSheet({super.key});

  @override
  ConsumerState<AddSellerSheet> createState() => _AddSellerSheetState();
}

class _AddSellerSheetState extends ConsumerState<AddSellerSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(databaseProvider).createSeller(name: _nameController.text.trim());
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
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Seller name'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save Seller')),
        ],
      ),
    );
  }
}
