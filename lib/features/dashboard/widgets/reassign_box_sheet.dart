import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';

class ReassignBoxSheet extends ConsumerStatefulWidget {
  const ReassignBoxSheet({super.key});

  @override
  ConsumerState<ReassignBoxSheet> createState() => _ReassignBoxSheetState();
}

class _ReassignBoxSheetState extends ConsumerState<ReassignBoxSheet> {
  final _boxNumberController = TextEditingController();
  final _sellerNameController = TextEditingController();

  @override
  void dispose() {
    _boxNumberController.dispose();
    _sellerNameController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final db = ref.read(databaseProvider);
    final box = await (db.select(db.boxes)
          ..where((tbl) => tbl.boxNumber.equals(_boxNumberController.text.trim())))
        .getSingle();

    final sellerRows = await (db.select(db.sellers)
          ..where((tbl) => tbl.name.equals(_sellerNameController.text.trim())))
        .get();

    final sellerId = sellerRows.isEmpty
        ? await db.createSeller(name: _sellerNameController.text.trim())
        : sellerRows.single.id;

    await db.reassignBox(boxId: box.id, nextSellerId: sellerId);
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
            key: const Key('reassign-box-number'),
            controller: _boxNumberController,
            decoration: const InputDecoration(labelText: 'Box number'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reassign-seller-name'),
            controller: _sellerNameController,
            decoration: const InputDecoration(labelText: 'Seller name'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _confirm,
            child: const Text('Confirm Reassignment'),
          ),
        ],
      ),
    );
  }
}
